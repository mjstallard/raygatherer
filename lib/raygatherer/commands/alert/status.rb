# frozen_string_literal: true

require "optparse"
require_relative "../../formatters/json"

module Raygatherer
  module Commands
    module Alert
      class Status
        SEVERITY_ORDER = {
          "Informational" => 0,
          "Low" => 1,
          "Medium" => 2,
          "High" => 3
        }.freeze

        def self.run(argv, stdout: $stdout, stderr: $stderr, verbose: false)
          new(argv, stdout: stdout, stderr: stderr, verbose: verbose).run
        end

        def initialize(argv, stdout: $stdout, stderr: $stderr, verbose: false)
          @argv = argv
          @stdout = stdout
          @stderr = stderr
          @verbose = verbose
          @host = nil
          @username = nil
          @password = nil
          @json = false
        end

        def run
          parse_options

          unless @host
            @stderr.puts "Error: --host is required"
            show_help(@stderr)
            return 1
          end

          api_client = ApiClient.new(
            @host,
            username: @username,
            password: @password,
            verbose: @verbose,
            stderr: @stderr
          )
          data = api_client.fetch_live_analysis_report
          alerts = extract_alerts(data[:rows])

          # Select formatter based on --json flag
          formatter = @json ? Formatters::JSON.new : Formatters::Human.new
          @stdout.puts formatter.format(alerts)

          # Return severity-based exit code
          severity_exit_code(alerts)
        rescue CLI::EarlyExit
          raise
        rescue ApiClient::ConnectionError, ApiClient::ApiError, ApiClient::ParseError => e
          @stderr.puts "Error: #{e.message}"
          1  # Generic error
        rescue => e
          @stderr.puts "Error: #{e.message}"
          1  # Generic error
        end

        private

        def parse_options
          OptionParser.new do |opts|
            opts.banner = "Usage: raygatherer alert status [options]"
            opts.separator ""
            opts.separator "Options:"

            opts.on("--host HOST", "Rayhunter host URL (required)") do |h|
              @host = h
            end

            opts.on("--basic-auth-user USER", "Basic auth username") do |u|
              @username = u
            end

            opts.on("--basic-auth-password PASS", "Basic auth password") do |p|
              @password = p
            end

            opts.on("--json", "Output JSON instead of human-readable format") do
              @json = true
            end

            opts.on("-h", "--help", "Show this help message") do
              show_help
              raise CLI::EarlyExit, 0
            end
          end.parse!(@argv)
        end

        def extract_alerts(rows)
          alerts = []

          rows.each do |row|
            events = row["events"] || []

            events.compact.each do |event|
              event_type = event["event_type"]
              next unless event_type

              severity_level = SEVERITY_ORDER[event_type] || 0
              next if severity_level == 0

              alerts << {
                severity: event_type,
                message: event["message"]
              }
            end
          end

          alerts
        end

        def show_help(output = @stdout)
          output.puts "Usage: raygatherer alert status [options]"
          output.puts ""
          output.puts "Options:"
          output.puts "    --host HOST                      Rayhunter host URL (required)"
          output.puts "    --basic-auth-user USER           Basic auth username"
          output.puts "    --basic-auth-password PASS       Basic auth password"
          output.puts "    --json                           Output JSON (for scripts/piping)"
          output.puts "    -h, --help                       Show this help message"
          output.puts ""
          output.puts "Exit Codes:"
          output.puts "    0   No alerts detected"
          output.puts "    1   Error (connection, parse, missing --host, etc.)"
          output.puts "    10  Low severity alert"
          output.puts "    11  Medium severity alert"
          output.puts "    12  High severity alert"
          output.puts ""
          output.puts "Examples:"
          output.puts "  raygatherer alert status --host http://192.168.1.100:8080"
          output.puts "  raygatherer alert status --host http://192.168.1.100:8080 --json | jq"
          output.puts "  raygatherer alert status --host http://rayhunter --json"
          output.puts "  [ $? -ge 11 ] && telegram-send 'Medium+ severity alert!'"
        end

        def severity_exit_code(alerts)
          return 0 if alerts.empty?

          max_severity = alerts.map { |a| SEVERITY_ORDER[a[:severity]] || 0 }.max
          case max_severity
          when 1 then 10
          when 2 then 11
          when 3 then 12
          else 0
          end
        end
      end
    end
  end
end
