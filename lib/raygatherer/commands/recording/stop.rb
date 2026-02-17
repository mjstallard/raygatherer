# frozen_string_literal: true

require "optparse"
require_relative "../base"

module Raygatherer
  module Commands
    module Recording
      class Stop < Base
        def run
          with_error_handling do
            parse_options

            if @argv.any?
              @stderr.puts "Error: recording stop does not take a name"
              next EXIT_CODE_ERROR
            end

            @api_client.stop_recording
            @stdout.puts "Recording stopped"
            EXIT_CODE_SUCCESS
          end
        end

        private

        def parse_options
          OptionParser.new do |opts|
            opts.banner = "Usage: raygatherer recording stop"
            opts.separator ""
            opts.separator "Options:"

            opts.on("-h", "--help", "Show this help message") do
              show_help
              raise CLI::EarlyExit, EXIT_CODE_SUCCESS
            end
          end.parse!(@argv)
        end

        def show_help(output = @stdout)
          output.puts "Usage: raygatherer [global options] recording stop"
          output.puts ""
          output.puts "Stops the current recording on the device."
          output.puts ""
          output.puts "Options:"
          output.puts "    -h, --help                       Show this help message"
          output.puts ""
          print_global_options(output)
          output.puts ""
          output.puts "Examples:"
          output.puts "  raygatherer --host http://192.168.1.100:8080 recording stop"
        end
      end
    end
  end
end
