# frozen_string_literal: true

require "optparse"
require_relative "../base"

module Raygatherer
  module Commands
    module Recording
      class Delete < Base
        def run
          with_error_handling do
            parse_options

            name = @argv.shift
            unless name
              @stderr.puts "Error: recording name is required"
              next 1
            end

            @api_client.delete_recording(name)
            @stdout.puts "Deleted recording: #{name}"
            0
          end
        end

        private

        def parse_options
          OptionParser.new do |opts|
            opts.banner = "Usage: raygatherer recording delete <name>"
            opts.separator ""
            opts.separator "Options:"

            opts.on("-h", "--help", "Show this help message") do
              show_help
              raise CLI::EarlyExit, 0
            end
          end.parse!(@argv)
        end

        def show_help(output = @stdout)
          output.puts "Usage: raygatherer [global options] recording delete <name>"
          output.puts ""
          output.puts "Options:"
          output.puts "    -h, --help                       Show this help message"
          output.puts ""
          print_global_options(output)
          output.puts ""
          output.puts "Examples:"
          output.puts "  raygatherer --host http://192.168.1.100:8080 recording delete 1738950000"
        end
      end
    end
  end
end
