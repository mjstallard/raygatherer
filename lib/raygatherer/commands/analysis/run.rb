# frozen_string_literal: true

require "optparse"
require_relative "../base"
require_relative "../../formatters/analysis_status_json"
require_relative "../../formatters/analysis_status_human"

module Raygatherer
  module Commands
    module Analysis
      class Run < Base
        def initialize(argv, stdout: $stdout, stderr: $stderr, api_client: nil, json: false)
          super(argv, stdout: stdout, stderr: stderr, api_client: api_client)
          @json = json
          @all = false
        end

        def run
          with_error_handling do
            parse_options

            name = @argv.shift

            if @all && name
              @stderr.puts "Error: cannot use --all with a recording name"
              return EXIT_CODE_ERROR
            end

            if !@all && name.nil?
              @stderr.puts "Error: recording name or --all is required"
              return EXIT_CODE_ERROR
            end

            status = @all ? run_all : @api_client.start_analysis(name)

            formatter = @json ? Formatters::AnalysisStatusJSON.new : Formatters::AnalysisStatusHuman.new
            @stdout.puts formatter.format(status)

            EXIT_CODE_SUCCESS
          end
        end

        private

        def run_all
          manifest = @api_client.fetch_manifest
          names = manifest["entries"].map { |e| e["name"] }
          names.each { |name| @api_client.start_analysis(name) }
          @api_client.fetch_analysis_status
        end

        def parse_options
          OptionParser.new do |opts|
            opts.banner = "Usage: raygatherer analysis run [options] [NAME]"
            opts.separator ""
            opts.separator "Options:"

            opts.on("--all", "Queue all recordings for analysis") do
              @all = true
            end

            opts.on("-h", "--help", "Show this help message") do
              show_help
              raise CLI::EarlyExit, EXIT_CODE_SUCCESS
            end
          end.parse!(@argv)
        end

        def show_help(output = @stdout)
          output.puts "Usage: raygatherer [global options] analysis run [options] [NAME]"
          output.puts ""
          output.puts "Queue a recording (or all recordings) for analysis."
          output.puts ""
          output.puts "Options:"
          output.puts "    --all                            Queue all recordings for analysis"
          output.puts "    -h, --help                       Show this help message"
          output.puts ""
          print_global_options(output, json: true)
          output.puts ""
          output.puts "Examples:"
          output.puts "  raygatherer --host http://192.168.1.100:8080 analysis run 1738950000"
          output.puts "  raygatherer --host http://192.168.1.100:8080 analysis run --all"
          output.puts "  raygatherer --host http://192.168.1.100:8080 --json analysis run --all"
        end
      end
    end
  end
end
