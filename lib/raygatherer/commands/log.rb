# frozen_string_literal: true

require "optparse"
require_relative "base"

module Raygatherer
  module Commands
    class Log < Base
      def run
        with_error_handling do
          parse_options
          @stdout.print @api_client.fetch_log
          EXIT_CODE_SUCCESS
        end
      end

      private

      def parse_options
        OptionParser.new do |opts|
          opts.on("-h", "--help", "Show this help message") do
            show_help
            raise CLI::EarlyExit, EXIT_CODE_SUCCESS
          end
        end.parse!(@argv)
      end

      def show_help(output = @stdout)
        output.puts "Usage: raygatherer [global options] log [options]"
        output.puts ""
        output.puts "Options:"
        output.puts "    -h, --help                       Show this help message"
        output.puts ""
        print_global_options(output)
        output.puts ""
        output.puts "Examples:"
        output.puts "  raygatherer --host http://192.168.1.100:8080 log"
      end
    end
  end
end
