# frozen_string_literal: true

require "httparty"
require "json"

module Raygatherer
  class ApiClient
    class ApiError < StandardError; end
    class ConnectionError < StandardError; end
    class ParseError < StandardError; end

    def initialize(host, username: nil, password: nil)
      @host = normalize_host(host)
      @username = username
      @password = password
    end

    def fetch_live_analysis_report
      options = {}
      options[:basic_auth] = { username: @username, password: @password } if @username && @password

      response = HTTParty.get("#{@host}/api/analysis-report/live", options)

      unless response.success?
        raise ApiError, "Server returned #{response.code}: #{response.message}"
      end

      parse_ndjson(response.body)
    rescue SocketError, Errno::ECONNREFUSED, Net::OpenTimeout, Net::ReadTimeout => e
      raise ConnectionError, "Failed to connect to #{@host}: #{e.message}"
    end

    private

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
