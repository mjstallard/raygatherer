# frozen_string_literal: true

require "json"
require "optparse"
require_relative "../base"

module Raygatherer
  module Commands
    module Debug
      class DisplayState < Base
        VALID_STATES = %w[recording paused warning].freeze
        VALID_SEVERITIES = %w[low medium high].freeze

        def initialize(argv, stdout: $stdout, stderr: $stderr, api_client: nil)
          super
          @severity = nil
        end

        def run
          with_error_handling do
            parse_options

            state = @argv.shift

            unless VALID_STATES.include?(state)
              @stderr.puts "Error: state must be one of: #{VALID_STATES.join(", ")}"
              return EXIT_CODE_ERROR
            end

            if state == "warning" && @severity.nil?
              @stderr.puts "Error: --severity is required when state is 'warning'"
              return EXIT_CODE_ERROR
            end

            if state != "warning" && !@severity.nil?
              @stderr.puts "Error: --severity is only valid when state is 'warning'"
              return EXIT_CODE_ERROR
            end

            @api_client.set_display_state(build_body(state))
            @stdout.puts "Display state updated."

            EXIT_CODE_SUCCESS
          end
        end

        private

        def build_body(state)
          case state
          when "recording" then JSON.generate("Recording")
          when "paused" then JSON.generate("Paused")
          when "warning" then JSON.generate({"WarningDetected" => {"event_type" => @severity.capitalize}})
          end
        end

        def parse_options
          OptionParser.new do |opts|
            opts.banner = "Usage: raygatherer debug display-state [options] STATE"
            opts.separator ""
            opts.separator "Options:"

            opts.on("--severity LEVEL", VALID_SEVERITIES, "Severity: low, medium, high (required for 'warning' state)") do |s|
              @severity = s
            end

            opts.on("-h", "--help", "Show this help message") do
              show_help
              raise CLI::EarlyExit, EXIT_CODE_SUCCESS
            end
          end.parse!(@argv)
        end

        def show_help(output = @stdout)
          output.puts "Usage: raygatherer [global options] debug display-state [options] STATE"
          output.puts ""
          output.puts "Change the display state of the device for debugging purposes."
          output.puts ""
          output.puts "States:"
          output.puts "    recording                        Device is recording, no warnings"
          output.puts "    paused                           Device is not recording"
          output.puts "    warning                          Warning detected (requires --severity)"
          output.puts ""
          output.puts "Options:"
          output.puts "    --severity LEVEL                 Warning severity: low, medium, high"
          output.puts "    -h, --help                       Show this help message"
          output.puts ""
          print_global_options(output)
          output.puts ""
          output.puts "Examples:"
          output.puts "  raygatherer --host http://192.168.1.100:8080 debug display-state recording"
          output.puts "  raygatherer --host http://192.168.1.100:8080 debug display-state paused"
          output.puts "  raygatherer --host http://192.168.1.100:8080 debug display-state warning --severity high"
        end
      end
    end
  end
end
