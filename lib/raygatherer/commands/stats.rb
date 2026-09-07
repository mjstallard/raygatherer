# frozen_string_literal: true

require "optparse"
require_relative "base"
require_relative "../formatters/stats_json"
require_relative "../formatters/stats_human"

module Raygatherer
  module Commands
    class Stats < Base
      def initialize(argv, stdout: $stdout, stderr: $stderr, api_client: nil, json: false)
        super(argv, stdout: stdout, stderr: stderr, api_client: api_client)
        @json = json
      end

      def run
        with_error_handling do
          parse_options

          stats = @api_client.fetch_system_stats

          rayhunter_version = stats.dig("runtime_metadata", "rayhunter_version")
          warn_if_rayhunter_outdated(rayhunter_version) if rayhunter_version

          formatter = @json ? Formatters::StatsJSON.new : Formatters::StatsHuman.new
          @stdout.puts formatter.format(stats)

          EXIT_CODE_SUCCESS
        end
      end

      private

      def parse_options
        OptionParser.new do |opts|
          opts.banner = "Usage: raygatherer stats [options]"
          opts.separator ""
          opts.separator "Options:"

          add_help_option(opts)
        end.parse!(@argv)
      end

      def show_help(output = @stdout)
        output.puts "Usage: raygatherer [global options] stats [options]"
        output.puts ""
        output.puts "Options:"
        output.puts "    -h, --help                       Show this help message"
        output.puts ""
        print_global_options(output, json: true)
        output.puts ""
        output.puts "Examples:"
        output.puts "  raygatherer --host http://192.168.1.100:8080 stats"
        output.puts "  raygatherer --host http://192.168.1.100:8080 --json stats"
      end
    end
  end
end
