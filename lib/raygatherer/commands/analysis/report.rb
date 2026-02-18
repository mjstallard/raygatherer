# frozen_string_literal: true

require "optparse"
require_relative "../base"
require_relative "../../formatters/analysis_report_json"
require_relative "../../formatters/analysis_report_human"

module Raygatherer
  module Commands
    module Analysis
      class Report < Base
        def initialize(argv, stdout: $stdout, stderr: $stderr, api_client: nil, json: false)
          super(argv, stdout: stdout, stderr: stderr, api_client: api_client)
          @json = json
        end

        def run
          with_error_handling do
            parse_options

            name = @argv.shift

            if name.nil?
              @stderr.puts "Error: recording name is required"
              return EXIT_CODE_ERROR
            end

            data = @api_client.fetch_analysis_report(name)

            formatter = @json ? Formatters::AnalysisReportJSON.new : Formatters::AnalysisReportHuman.new
            @stdout.puts formatter.format(data)

            EXIT_CODE_SUCCESS
          end
        end

        private

        def parse_options
          OptionParser.new do |opts|
            opts.banner = "Usage: raygatherer analysis report [options] NAME"
            opts.separator ""
            opts.separator "Options:"

            opts.on("-h", "--help", "Show this help message") do
              show_help
              raise CLI::EarlyExit, EXIT_CODE_SUCCESS
            end
          end.parse!(@argv)
        end

        def show_help(output = @stdout)
          output.puts "Usage: raygatherer [global options] analysis report [options] NAME"
          output.puts ""
          output.puts "Show the full analysis report for a named recording."
          output.puts ""
          output.puts "Options:"
          output.puts "    -h, --help                       Show this help message"
          output.puts ""
          print_global_options(output, json: true)
          output.puts ""
          output.puts "Examples:"
          output.puts "  raygatherer --host http://192.168.1.100:8080 analysis report 1738950000"
          output.puts "  raygatherer --host http://rayhunter --json analysis report 1738950000"
        end
      end
    end
  end
end
