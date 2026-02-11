# frozen_string_literal: true

require "httparty"
require "json"

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
      options = {}
      options[:basic_auth] = { username: @username, password: @password } if @username && @password

      log_verbose "HTTP GET #{@host}/api/analysis-report/live"
      log_verbose "Basic Auth: user=#{@username}" if @username

      start_time = Time.now
      log_verbose "Request started at: #{start_time.utc}"

      response = HTTParty.get("#{@host}/api/analysis-report/live", options)

      elapsed = Time.now - start_time
      status_text = response.code == 200 ? "OK" : response.message.to_s
      log_verbose "Response received: #{response.code} #{status_text} (#{format('%.3f', elapsed)}s)"

      # CRITICAL: Log raw body BEFORE any parsing attempt
      log_verbose "Raw response body (#{response.body.bytesize} bytes):"
      log_verbose response.body if @verbose

      unless response.success?
        raise ApiError, "Server returned #{response.code}: #{response.message}"
      end

      log_verbose "Parsing NDJSON response..."
      result = parse_ndjson(response.body)
      log_verbose "Parsed successfully: metadata + #{result[:rows].length} rows"

      result
    rescue SocketError, Errno::ECONNREFUSED, Net::OpenTimeout, Net::ReadTimeout => e
      log_verbose "Connection error: #{e.class} - #{e.message}"
      raise ConnectionError, "Failed to connect to #{@host}: #{e.message}"
    rescue ParseError => e
      log_verbose "Parse failed: #{e.message}"
      raise
    end

    def fetch_manifest
      options = {}
      options[:basic_auth] = { username: @username, password: @password } if @username && @password

      log_verbose "HTTP GET #{@host}/api/qmdl-manifest"
      log_verbose "Basic Auth: user=#{@username}" if @username

      start_time = Time.now
      log_verbose "Request started at: #{start_time.utc}"

      response = HTTParty.get("#{@host}/api/qmdl-manifest", options)

      elapsed = Time.now - start_time
      status_text = response.code == 200 ? "OK" : response.message.to_s
      log_verbose "Response received: #{response.code} #{status_text} (#{format('%.3f', elapsed)}s)"

      log_verbose "Raw response body (#{response.body.bytesize} bytes):"
      log_verbose response.body if @verbose

      unless response.success?
        raise ApiError, "Server returned #{response.code}: #{response.message}"
      end

      log_verbose "Parsing JSON response..."
      result = parse_json(response.body)
      log_verbose "Parsed successfully: #{result['entries']&.length || 0} entries"

      result
    rescue SocketError, Errno::ECONNREFUSED, Net::OpenTimeout, Net::ReadTimeout => e
      log_verbose "Connection error: #{e.class} - #{e.message}"
      raise ConnectionError, "Failed to connect to #{@host}: #{e.message}"
    rescue ParseError => e
      log_verbose "Parse failed: #{e.message}"
      raise
    end

    private

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

      { metadata: metadata, rows: rows }
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
      if host !~ %r{^https?://}
        "http://#{host}"
      else
        host
      end
    end
  end
end
