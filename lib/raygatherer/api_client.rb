# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

module Raygatherer
  class ApiClient
    class ApiError < StandardError; end
    class ConnectionError < StandardError; end
    class ParseError < StandardError; end

    def initialize(host, username: nil, password: nil, verbose: false, stderr: $stderr)
      @host = normalize_host(host)
      @username = username
      @password = password
      @verbose = verbose
      @stderr = stderr
    end

    def fetch_live_analysis_report
      get("/api/analysis-report/live") do |body|
        log_verbose "Parsing NDJSON response..."
        result = parse_ndjson(body)
        log_verbose "Parsed successfully: metadata + #{result[:rows].length} rows"
        result
      end
    end

    def fetch_analysis_report(name)
      encoded = URI.encode_www_form_component(name)
      get("/api/analysis-report/#{encoded}") do |body|
        log_verbose "Parsing NDJSON response..."
        result = parse_ndjson(body)
        log_verbose "Parsed successfully: metadata + #{result[:rows].length} rows"
        result
      end
    end

    def fetch_manifest
      get("/api/qmdl-manifest") do |body|
        log_verbose "Parsing JSON response..."
        result = parse_json(body)
        log_verbose "Parsed successfully: #{result["entries"]&.length || 0} entries"
        result
      end
    end

    def fetch_analysis_status
      get("/api/analysis") do |body|
        log_verbose "Parsing JSON response..."
        result = parse_json(body)
        log_verbose "Parsed successfully"
        result
      end
    end

    def fetch_system_stats
      get("/api/system-stats") do |body|
        log_verbose "Parsing JSON response..."
        result = parse_json(body)
        log_verbose "Parsed successfully"
        result
      end
    end

    def download_recording(name, io:, format: :qmdl)
      encoded = URI.encode_www_form_component(name)
      path = case format
      when :qmdl then "/api/qmdl/#{encoded}"
      when :pcap then "/api/pcap/#{encoded}"
      when :zip then "/api/zip/#{encoded}"
      end
      stream_to(path, io)
    end

    def delete_recording(name)
      post("/api/delete-recording/#{URI.encode_www_form_component(name)}")
    end

    def start_analysis(name)
      encoded = URI.encode_www_form_component(name)
      body = post("/api/analysis/#{encoded}")
      parse_json(body)
    end

    def stop_recording
      post("/api/stop-recording")
    end

    def start_recording
      post("/api/start-recording")
    end

    private

    def get(path)
      response, body = request(:get, path, ok_code: "200", ok_status_text: "OK")

      unless response.is_a?(Net::HTTPSuccess)
        raise ApiError, server_error_message(response, body)
      end

      yield body
    rescue ParseError => e
      log_verbose "Parse failed: #{e.message}"
      raise
    end

    def post(path, expected_code: "202")
      ok_status_text = (expected_code == "202") ? "Accepted" : "OK"
      response, body = request(:post, path, ok_code: expected_code, ok_status_text: ok_status_text)

      unless response.code == expected_code
        raise ApiError, server_error_message(response, body)
      end

      body
    end

    def request(method, path, ok_code:, ok_status_text:)
      url = "#{@host}#{path}"
      uri = URI.parse(url)

      log_verbose "HTTP #{method.to_s.upcase} #{url}"
      log_verbose "Basic Auth: user=#{@username}" if @username

      start_time = Time.now
      log_verbose "Request started at: #{start_time.utc}"

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")

      req = case method
      when :get then Net::HTTP::Get.new(uri.request_uri)
      when :post then Net::HTTP::Post.new(uri.request_uri)
      end
      req.basic_auth(@username, @password) if @username && @password

      response = http.request(req)

      elapsed = Time.now - start_time
      status_text = (response.code == ok_code) ? ok_status_text : response.message.to_s
      log_verbose "Response received: #{response.code} #{status_text} (#{format("%.3f", elapsed)}s)"

      body = response.body.to_s
      log_verbose "Raw response body (#{body.bytesize} bytes):"
      log_verbose body if @verbose

      [response, body]
    rescue SocketError, Errno::ECONNREFUSED, Net::OpenTimeout, Net::ReadTimeout => e
      log_verbose "Connection error: #{e.class} - #{e.message}"
      raise ConnectionError, "Failed to connect to #{@host}: #{e.message}"
    end

    def stream_to(path, io)
      uri = URI.parse("#{@host}#{path}")

      log_verbose "HTTP GET #{uri} (streaming)"

      start_time = Time.now
      log_verbose "Request started at: #{start_time.utc}"

      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
        request = Net::HTTP::Get.new(uri.request_uri)
        request.basic_auth(@username, @password) if @username && @password

        http.request(request) do |response|
          elapsed = Time.now - start_time
          status_text = (response.code == "200") ? "OK" : response.message.to_s
          log_verbose "Response received: #{response.code} #{status_text} (#{format("%.3f", elapsed)}s)"

          unless response.is_a?(Net::HTTPSuccess)
            error_body = response.read_body
            raise ApiError, server_error_message(response, error_body)
          end

          response.read_body do |chunk|
            io.write(chunk)
          end
        end
      end
    rescue SocketError, Errno::ECONNREFUSED, Net::OpenTimeout, Net::ReadTimeout => e
      log_verbose "Connection error: #{e.class} - #{e.message}"
      raise ConnectionError, "Failed to connect to #{@host}: #{e.message}"
    end

    def server_error_message(response, body)
      detail = body.to_s.strip
      detail = response.message if detail.empty?
      "Server returned #{response.code}: #{detail}"
    end

    def log_verbose(message)
      return unless @verbose
      @stderr.puts message
    end

    def parse_ndjson(body)
      lines = body.split("\n").reject(&:empty?)

      raise ParseError, "No data received from server" if lines.empty?

      metadata = parse_line(lines.first, "metadata")
      rows = lines[1..].map.with_index do |line, index|
        parse_line(line, "row #{index + 1}")
      end

      {metadata: metadata, rows: rows}
    rescue JSON::ParserError => e
      raise ParseError, "Failed to parse response: #{e.message}"
    end

    def parse_line(line, context)
      JSON.parse(line)
    rescue JSON::ParserError => e
      raise ParseError, "Failed to parse #{context}: #{e.message}"
    end

    def parse_json(body)
      JSON.parse(body)
    rescue JSON::ParserError => e
      raise ParseError, "Failed to parse response: #{e.message}"
    end

    def normalize_host(host)
      # Add http:// if no scheme is present
      if !%r{^https?://}.match?(host)
        "http://#{host}"
      else
        host
      end
    end
  end
end
