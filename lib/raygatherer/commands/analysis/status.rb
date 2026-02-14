# frozen_string_literal: true

require "optparse"
require_relative "../base"
require_relative "../../formatters/analysis_status_json"
require_relative "../../formatters/analysis_status_human"

module Raygatherer
  module Commands
    module Analysis
      class Status < Base
        def initialize(argv, stdout: $stdout, stderr: $stderr, api_client: nil, json: false)
          super(argv, stdout: stdout, stderr: stderr, api_client: api_client)
          @json = json
        end

        def run
          with_error_handling do
            parse_options

            status = @api_client.fetch_analysis_status

            formatter = @json ? Formatters::AnalysisStatusJSON.new : Formatters::AnalysisStatusHuman.new
            @stdout.puts formatter.format(status)

            0
          end
        end

        private

        def parse_options
          OptionParser.new do |opts|
            opts.banner = "Usage: raygatherer analysis status [options]"
            opts.separator ""
            opts.separator "Options:"

            opts.on("-h", "--help", "Show this help message") do
              show_help
              raise CLI::EarlyExit, 0
            end
          end.parse!(@argv)
        end

        def show_help(output = @stdout)
          output.puts "Usage: raygatherer [global options] analysis status [options]"
          output.puts ""
          output.puts "Options:"
          output.puts "    -h, --help                       Show this help message"
          output.puts ""
          print_global_options(output, json: true)
          output.puts ""
          output.puts "Examples:"
          output.puts "  raygatherer --host http://192.168.1.100:8080 analysis status"
          output.puts "  raygatherer --host http://192.168.1.100:8080 --json analysis status"
        end
      end
    end
  end
end
