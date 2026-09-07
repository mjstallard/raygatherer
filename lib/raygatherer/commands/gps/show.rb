# frozen_string_literal: true

require "optparse"
require_relative "../base"
require_relative "../../formatters/gps_json"
require_relative "../../formatters/gps_human"

module Raygatherer
  module Commands
    module Gps
      class Show < Base
        def initialize(argv, stdout: $stdout, stderr: $stderr, api_client: nil, json: false)
          super(argv, stdout: stdout, stderr: stderr, api_client: api_client)
          @json = json
        end

        def run
          with_error_handling do
            parse_options

            gps = @api_client.fetch_gps

            formatter = @json ? Formatters::GpsJSON.new : Formatters::GpsHuman.new
            @stdout.puts formatter.format(gps)

            EXIT_CODE_SUCCESS
          end
        end

        private

        def parse_options
          OptionParser.new do |opts|
            opts.banner = "Usage: raygatherer gps show [options]"
            opts.separator ""
            opts.separator "Options:"

            opts.on("-h", "--help", "Show this help message") do
              show_help
              raise CLI::EarlyExit, EXIT_CODE_SUCCESS
            end
          end.parse!(@argv)
        end

        def show_help(output = @stdout)
          output.puts "Usage: raygatherer [global options] gps show [options]"
          output.puts ""
          output.puts "Show the last GPS position submitted to the device (see 'gps set')."
          output.puts ""
          output.puts "Options:"
          output.puts "    -h, --help                       Show this help message"
          output.puts ""
          print_global_options(output, json: true)
          output.puts ""
          output.puts "Examples:"
          output.puts "  raygatherer --host http://192.168.1.100:8080 gps show"
          output.puts "  raygatherer --host http://192.168.1.100:8080 --json gps show"
        end
      end
    end
  end
end
