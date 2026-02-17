# frozen_string_literal: true

require "optparse"
require_relative "../base"
require_relative "../../formatters/recording_list_json"
require_relative "../../formatters/recording_list_human"

module Raygatherer
  module Commands
    module Recording
      class List < Base
        def initialize(argv, stdout: $stdout, stderr: $stderr, api_client: nil, json: false)
          super(argv, stdout: stdout, stderr: stderr, api_client: api_client)
          @json = json
        end

        def run
          with_error_handling do
            parse_options

            manifest = @api_client.fetch_manifest

            formatter = @json ? Formatters::RecordingListJSON.new : Formatters::RecordingListHuman.new
            @stdout.puts formatter.format(manifest)

            EXIT_CODE_SUCCESS
          end
        end

        private

        def parse_options
          OptionParser.new do |opts|
            opts.banner = "Usage: raygatherer recording list [options]"
            opts.separator ""
            opts.separator "Options:"

            opts.on("-h", "--help", "Show this help message") do
              show_help
              raise CLI::EarlyExit, EXIT_CODE_SUCCESS
            end
          end.parse!(@argv)
        end

        def show_help(output = @stdout)
          output.puts "Usage: raygatherer [global options] recording list [options]"
          output.puts ""
          output.puts "Options:"
          output.puts "    -h, --help                       Show this help message"
          output.puts ""
          print_global_options(output, json: true)
          output.puts ""
          output.puts "Examples:"
          output.puts "  raygatherer --host http://192.168.1.100:8080 recording list"
          output.puts "  raygatherer --host http://192.168.1.100:8080 --json recording list"
        end
      end
    end
  end
end
