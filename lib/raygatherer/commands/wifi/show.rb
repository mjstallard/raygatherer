# frozen_string_literal: true

require "optparse"
require_relative "../base"
require_relative "../../formatters/wifi_status_json"
require_relative "../../formatters/wifi_status_human"

module Raygatherer
  module Commands
    module Wifi
      class Show < Base
        def run
          with_error_handling do
            parse_options

            status = @api_client.fetch_wifi_status

            formatter = @json ? Formatters::WifiStatusJSON.new : Formatters::WifiStatusHuman.new
            @stdout.puts formatter.format(status)

            EXIT_CODE_SUCCESS
          end
        end

        private

        def parse_options
          OptionParser.new do |opts|
            opts.banner = "Usage: raygatherer wifi show [options]"
            opts.separator ""
            opts.separator "Options:"

            add_help_option(opts)
          end.parse!(@argv)
        end

        def show_help(output = @stdout)
          output.puts "Usage: raygatherer [global options] wifi show [options]"
          output.puts ""
          output.puts "Show the device's wifi client connection status (the daemon's own outbound"
          output.puts "connection to an upstream network, separate from the AP it hosts)."
          output.puts ""
          output.puts "Options:"
          output.puts "    -h, --help                       Show this help message"
          output.puts ""
          print_global_options(output, json: true)
          output.puts ""
          output.puts "Examples:"
          output.puts "  raygatherer --host http://192.168.1.100:8080 wifi show"
          output.puts "  raygatherer --host http://192.168.1.100:8080 --json wifi show"
        end
      end
    end
  end
end
