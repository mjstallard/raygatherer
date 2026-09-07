# frozen_string_literal: true

require "optparse"
require_relative "../base"
require_relative "../../formatters/config_json"
require_relative "../../formatters/config_human"

module Raygatherer
  module Commands
    module Config
      class Show < Base
        def self.supports_json?
          true
        end

        def run
          with_error_handling do
            parse_options

            config = @api_client.fetch_config

            formatter = @json ? Formatters::ConfigJSON.new : Formatters::ConfigHuman.new
            @stdout.puts formatter.format(config)

            EXIT_CODE_SUCCESS
          end
        end

        private

        def parse_options
          OptionParser.new do |opts|
            opts.banner = "Usage: raygatherer config show [options]"
            opts.separator ""
            opts.separator "Options:"

            add_help_option(opts)
          end.parse!(@argv)
        end

        def show_help(output = @stdout)
          output.puts "Usage: raygatherer [global options] config show [options]"
          output.puts ""
          output.puts "Options:"
          output.puts "    -h, --help                       Show this help message"
          output.puts ""
          print_global_options(output)
          output.puts ""
          output.puts "Examples:"
          output.puts "  raygatherer --host http://192.168.1.100:8080 config show"
          output.puts "  raygatherer --host http://192.168.1.100:8080 --json config show"
          output.puts "  raygatherer --host http://rayhunter --json config show | jq '.analyzers'"
        end
      end
    end
  end
end
