# frozen_string_literal: true

require "optparse"
require_relative "../base"
require_relative "../../formatters/update_status_json"
require_relative "../../formatters/update_status_human"

module Raygatherer
  module Commands
    module Update
      class Status < Base
        EXIT_CODE_UPDATE_AVAILABLE = 20

        def initialize(argv, stdout: $stdout, stderr: $stderr, api_client: nil, json: false)
          super(argv, stdout: stdout, stderr: stderr, api_client: api_client)
          @json = json
        end

        def run
          with_error_handling do
            parse_options

            status = @api_client.fetch_update_status

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

            opts.on("-h", "--help", "Show this help message") do
              show_help
              raise CLI::EarlyExit, EXIT_CODE_SUCCESS
            end
          end.parse!(@argv)
        end

        def show_help(output = @stdout)
          output.puts "Usage: raygatherer [global options] update status [options]"
          output.puts ""
          output.puts "Options:"
          output.puts "    -h, --help                       Show this help message"
          output.puts ""
          print_global_options(output, json: true)
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
