# frozen_string_literal: true

require "optparse"

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
          alert = extract_alert(data[:rows])

          formatter = Formatters::Human.new
          @stdout.puts formatter.format(alert)

          0
        rescue CLI::EarlyExit
          raise
        rescue => e
          @stderr.puts "Error: #{e.message}"
          1
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

            opts.on("-h", "--help", "Show this help message") do
              show_help
              raise CLI::EarlyExit, 0
            end
          end.parse!(@argv)
        end

        def extract_alert(rows)
          highest_alert = nil
          highest_severity = 0

          rows.each do |row|
            events = row["events"] || []

            events.compact.each do |event|
              event_type = event["event_type"]
              next unless event_type

              severity_level = SEVERITY_ORDER[event_type] || 0

              # Skip Informational events
              next if severity_level == 0

              if severity_level > highest_severity
                highest_severity = severity_level
                highest_alert = {
                  severity: event_type,
                  message: event["message"]
                }
              end
            end
          end

          highest_alert
        end

        def show_help(output = @stdout)
          output.puts "Usage: raygatherer alert status [options]"
          output.puts ""
          output.puts "Options:"
          output.puts "    --host HOST                      Rayhunter host URL (required)"
          output.puts "    --basic-auth-user USER           Basic auth username"
          output.puts "    --basic-auth-password PASS       Basic auth password"
          output.puts "    -h, --help                       Show this help message"
          output.puts ""
          output.puts "Examples:"
          output.puts "  raygatherer alert status --host http://192.168.1.100:8080"
          output.puts "  raygatherer alert status --host http://192.168.1.100:8080 --basic-auth-user admin --basic-auth-password secret"
        end
      end
    end
  end
end
