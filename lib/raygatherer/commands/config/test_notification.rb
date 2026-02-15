# frozen_string_literal: true

require "optparse"
require_relative "../base"

module Raygatherer
  module Commands
    module Config
      class TestNotification < Base
        def run
          with_error_handling do
            parse_options

            @api_client.test_notification
            @stdout.puts "Test notification sent successfully."

            0
          end
        end

        private

        def parse_options
          OptionParser.new do |opts|
            opts.banner = "Usage: raygatherer config test-notification [options]"
            opts.separator ""
            opts.separator "Options:"

            opts.on("-h", "--help", "Show this help message") do
              show_help
              raise CLI::EarlyExit, 0
            end
          end.parse!(@argv)
        end

        def show_help(output = @stdout)
          output.puts "Usage: raygatherer [global options] config test-notification [options]"
          output.puts ""
          output.puts "Sends a test notification to the configured notification URL."
          output.puts ""
          output.puts "Options:"
          output.puts "    -h, --help                       Show this help message"
          output.puts ""
          print_global_options(output)
          output.puts ""
          output.puts "Examples:"
          output.puts "  raygatherer --host http://192.168.1.100:8080 config test-notification"
        end
      end
    end
  end
end
