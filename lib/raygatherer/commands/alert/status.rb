# frozen_string_literal: true

require "optparse"
require_relative "../base"
require_relative "../../formatters/json"

module Raygatherer
  module Commands
    module Alert
      class Status < Base
        SEVERITY_ORDER = {
          "Informational" => 0,
          "Low" => 1,
          "Medium" => 2,
          "High" => 3
        }.freeze

        def initialize(argv, stdout: $stdout, stderr: $stderr, api_client: nil, json: false)
          super(argv, stdout: stdout, stderr: stderr, api_client: api_client)
          @json = json
          @latest = false
        end

        def run
          with_error_handling(extra_errors: [ApiClient::ParseError]) do
            parse_options

            data = @api_client.fetch_live_analysis_report
            alerts = extract_alerts(data[:rows], data[:metadata])
            alerts = filter_latest(alerts, data[:rows]) if @latest

            # Select formatter based on --json flag
            formatter = @json ? Formatters::JSON.new : Formatters::Human.new
            @stdout.puts formatter.format(alerts)

            # Return severity-based exit code
            severity_exit_code(alerts)
          end
        end

        private

        def parse_options
          OptionParser.new do |opts|
            opts.banner = "Usage: raygatherer alert status [options]"
            opts.separator ""
            opts.separator "Options:"

            opts.on("--latest", "Show only alerts from the most recent message") do
              @latest = true
            end

            opts.on("-h", "--help", "Show this help message") do
              show_help
              raise CLI::EarlyExit, 0
            end
          end.parse!(@argv)
        end

        def extract_alerts(rows, metadata)
          analyzers = metadata&.dig("analyzers") || []
          alerts = []

          rows.each do |row|
            events = row["events"] || []

            events.each_with_index do |event, index|
              next if event.nil?

              event_type = event["event_type"]
              next unless event_type

              severity_level = SEVERITY_ORDER[event_type] || 0
              next if severity_level == 0

              alerts << {
                severity: event_type,
                message: event["message"],
                packet_timestamp: row["packet_timestamp"],
                analyzer: analyzers.dig(index, "name")
              }
            end
          end

          alerts
        end

        def filter_latest(alerts, rows)
          latest_timestamp = rows.map { |r| r["packet_timestamp"] }.max
          return [] if latest_timestamp.nil?

          alerts.select { |a| a[:packet_timestamp] == latest_timestamp }
        end

        def show_help(output = @stdout)
          output.puts "Usage: raygatherer [global options] alert status [options]"
          output.puts ""
          output.puts "Options:"
          output.puts "    --latest                         Show only alerts from the most recent message"
          output.puts "    -h, --help                       Show this help message"
          output.puts ""
          output.puts "Global options (see 'raygatherer --help'):"
          output.puts "    --host, --basic-auth-user, --basic-auth-password, --json, --verbose"
          output.puts ""
          output.puts "Exit Codes:"
          output.puts "    0   No alerts detected"
          output.puts "    1   Error (connection, parse, missing --host, etc.)"
          output.puts "    10  Low severity alert"
          output.puts "    11  Medium severity alert"
          output.puts "    12  High severity alert"
          output.puts ""
          output.puts "Examples:"
          output.puts "  raygatherer --host http://192.168.1.100:8080 alert status"
          output.puts "  raygatherer --host http://192.168.1.100:8080 --json alert status"
          output.puts "  raygatherer --host http://rayhunter --json alert status"
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
