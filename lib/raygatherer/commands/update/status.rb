# frozen_string_literal: true

require "optparse"
require_relative "../base"
require_relative "../../formatters/update_status_json"
require_relative "../../formatters/update_status_human"

module Raygatherer
  module Commands
    module Update
      class Status < Base
        def self.supports_json?
          true
        end

        EXIT_CODE_UPDATE_AVAILABLE = 20

        def run
          with_error_handling do
            parse_options

            status = @api_client.fetch_update_status

            warn_if_rayhunter_outdated(status["current_version"]) if status["current_version"]

            formatter = @json ? Formatters::UpdateStatusJSON.new : Formatters::UpdateStatusHuman.new
            @stdout.puts formatter.format(status)

            status["update_available"] ? EXIT_CODE_UPDATE_AVAILABLE : EXIT_CODE_SUCCESS
          end
        end

        private

        def parse_options
          OptionParser.new do |opts|
            opts.banner = "Usage: raygatherer update status [options]"
            opts.separator ""
            opts.separator "Options:"

            add_help_option(opts)
          end.parse!(@argv)
        end

        def show_help(output = @stdout)
          output.puts "Usage: raygatherer [global options] update status [options]"
          output.puts ""
          output.puts "Options:"
          output.puts "    -h, --help                       Show this help message"
          output.puts ""
          print_global_options(output)
          output.puts ""
          output.puts "Exit Codes:"
          output.puts "    #{EXIT_CODE_SUCCESS}   Up to date (or auto_check_updates is disabled on the device)"
          output.puts "    #{EXIT_CODE_ERROR}   Error (connection, parse, missing --host, etc.)"
          output.puts "    #{EXIT_CODE_UPDATE_AVAILABLE}  Update available"
          output.puts ""
          output.puts "Examples:"
          output.puts "  raygatherer --host http://192.168.1.100:8080 update status"
          output.puts "  raygatherer --host http://192.168.1.100:8080 --json update status"
          output.puts "  raygatherer --host http://rayhunter update status; [ $? -eq #{EXIT_CODE_UPDATE_AVAILABLE} ] && telegram-send 'Rayhunter update available!'"
        end
      end
    end
  end
end
