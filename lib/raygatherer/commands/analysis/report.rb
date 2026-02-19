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
          @live = false
        end

        def run
          with_error_handling do
            parse_options

            name = @argv.shift

            if @live && name
              @stderr.puts "Error: cannot use --live with a recording name"
              return EXIT_CODE_ERROR
            end

            if !@live && name.nil?
              @stderr.puts "Error: recording name or --live is required"
              return EXIT_CODE_ERROR
            end

            data = @live ? @api_client.fetch_live_analysis_report : @api_client.fetch_analysis_report(name)

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

            opts.on("--live", "Show analysis report for the currently active recording") do
              @live = true
            end

            opts.on("-h", "--help", "Show this help message") do
              show_help
              raise CLI::EarlyExit, EXIT_CODE_SUCCESS
            end
          end.parse!(@argv)
        end

        def show_help(output = @stdout)
          output.puts "Usage: raygatherer [global options] analysis report [options] [NAME]"
          output.puts ""
          output.puts "Show the full analysis report for a named recording, or the active recording."
          output.puts ""
          output.puts "Options:"
          output.puts "        --live                           Show analysis report for the currently active recording"
          output.puts "    -h, --help                           Show this help message"
          output.puts ""
          print_global_options(output, json: true)
          output.puts ""
          output.puts "Examples:"
          output.puts "  raygatherer --host http://192.168.1.100:8080 analysis report 1738950000"
          output.puts "  raygatherer --host http://rayhunter --json analysis report 1738950000"
          output.puts "  raygatherer --host http://rayhunter analysis report --live"
        end
      end
    end
  end
end
