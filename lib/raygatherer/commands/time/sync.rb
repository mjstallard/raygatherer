# frozen_string_literal: true

require "optparse"
require "time"
require_relative "../base"

module Raygatherer
  module Commands
    module Time
      class Sync < Base
        def run
          with_error_handling do
            parse_options

            time_data = @api_client.fetch_time
            device_system_time = ::Time.parse(time_data["system_time"])
            offset = (::Time.now - device_system_time).round
            @api_client.set_time_offset(offset)
            @stdout.puts "Clock synced. Offset: #{offset}s"

            EXIT_CODE_SUCCESS
          end
        end

        private

        def parse_options
          OptionParser.new do |opts|
            opts.banner = "Usage: raygatherer time sync"
            opts.separator ""
            opts.separator "Options:"

            opts.on("-h", "--help", "Show this help message") do
              show_help
              raise CLI::EarlyExit, EXIT_CODE_SUCCESS
            end
          end.parse!(@argv)
        end

        def show_help(output = @stdout)
          output.puts "Usage: raygatherer [global options] time sync"
          output.puts ""
          output.puts "Syncs the device clock to this machine's time."
          output.puts ""
          output.puts "Options:"
          output.puts "    -h, --help                       Show this help message"
          output.puts ""
          print_global_options(output)
          output.puts ""
          output.puts "Examples:"
          output.puts "  raygatherer --host http://192.168.1.100:8080 time sync"
        end
      end
    end
  end
end
