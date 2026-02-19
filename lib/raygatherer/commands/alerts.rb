# frozen_string_literal: true

require "optparse"
require "time"
require_relative "base"
require_relative "../formatters/json"

module Raygatherer
  module Commands
    class Alerts < Base
      SEVERITY_ORDER = {
        "Informational" => 0,
        "Low" => 1,
        "Medium" => 2,
        "High" => 3
      }.freeze

      EXIT_CODE_LOW_SEVERITY = 10
      EXIT_CODE_MEDIUM_SEVERITY = 11
      EXIT_CODE_HIGH_SEVERITY = 12

      def initialize(argv, stdout: $stdout, stderr: $stderr, api_client: nil, json: false)
        super(argv, stdout: stdout, stderr: stderr, api_client: api_client)
        @json = json
        @latest = false
        @after = nil
        @recording = nil
      end

      def run
        with_error_handling do
          parse_options

          data = if @recording
            @api_client.fetch_analysis_report(@recording)
          else
            @api_client.fetch_live_analysis_report
          end
          alerts = extract_alerts(data[:rows], data[:metadata])
          alerts = filter_after(alerts) if @after
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
          opts.banner = "Usage: raygatherer alerts [options]"
          opts.separator ""
          opts.separator "Options:"

          opts.on("--recording NAME", "Analyze a past recording instead of live") do |name|
            @recording = name
          end

          opts.on("--latest", "Show only alerts from the most recent message") do
            @latest = true
          end

          opts.on("--after TIMESTAMP", "Show only alerts after this time (ISO 8601)") do |ts|
            @after = parse_timestamp(ts)
          end

          opts.on("-h", "--help", "Show this help message") do
            show_help
            raise CLI::EarlyExit, EXIT_CODE_SUCCESS
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

      def parse_timestamp(str)
        ::Time.parse(str)
      rescue ArgumentError
        raise ArgumentError, "invalid timestamp: #{str}"
      end

      def filter_after(alerts)
        alerts.select { |a| a[:packet_timestamp] && ::Time.parse(a[:packet_timestamp]) > @after }
      end

      def filter_latest(alerts, rows)
        latest_timestamp = if @after
          alerts.map { |a| a[:packet_timestamp] }.compact.max
        else
          rows.map { |r| r["packet_timestamp"] }.compact.max
        end
        return [] if latest_timestamp.nil?

        alerts.select { |a| a[:packet_timestamp] == latest_timestamp }
      end

      def show_help(output = @stdout)
        output.puts "Usage: raygatherer [global options] alerts [options]"
        output.puts ""
        output.puts "Options:"
        output.puts "    --recording NAME                 Analyze a past recording instead of live"
        output.puts "    --after TIMESTAMP                Show only alerts after this time (ISO 8601, exclusive)"
        output.puts "    --latest                         Show only alerts from the most recent message"
        output.puts "    -h, --help                       Show this help message"
        output.puts ""
        print_global_options(output, json: true)
        output.puts ""
        output.puts "Exit Codes:"
        output.puts "    #{EXIT_CODE_SUCCESS}   No alerts detected"
        output.puts "    #{EXIT_CODE_ERROR}   Error (connection, parse, missing --host, etc.)"
        output.puts "    #{EXIT_CODE_LOW_SEVERITY}  Low severity alert"
        output.puts "    #{EXIT_CODE_MEDIUM_SEVERITY}  Medium severity alert"
        output.puts "    #{EXIT_CODE_HIGH_SEVERITY}  High severity alert"
        output.puts ""
        output.puts "Examples:"
        output.puts "  raygatherer --host http://192.168.1.100:8080 alerts"
        output.puts "  raygatherer --host http://192.168.1.100:8080 --json alerts"
        output.puts "  raygatherer --host http://rayhunter --json alerts"
        output.puts "  raygatherer --host http://rayhunter alerts --after 2024-02-07T14:25:33Z"
        output.puts "  [ $? -ge #{EXIT_CODE_MEDIUM_SEVERITY} ] && telegram-send 'Medium+ severity alert!'"
      end

      def severity_exit_code(alerts)
        return EXIT_CODE_SUCCESS if alerts.empty?

        max_severity = alerts.map { |a| SEVERITY_ORDER[a[:severity]] || 0 }.max
        case max_severity
        when 1 then EXIT_CODE_LOW_SEVERITY
        when 2 then EXIT_CODE_MEDIUM_SEVERITY
        when 3 then EXIT_CODE_HIGH_SEVERITY
        else EXIT_CODE_SUCCESS
        end
      end
    end
  end
end
