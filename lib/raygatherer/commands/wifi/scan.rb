# frozen_string_literal: true

require "optparse"
require_relative "../base"
require_relative "../../formatters/wifi_scan_json"
require_relative "../../formatters/wifi_scan_human"

module Raygatherer
  module Commands
    module Wifi
      class Scan < Base
        def self.supports_json?
          true
        end

        def run
          with_error_handling do
            parse_options

            networks = @api_client.scan_wifi

            formatter = @json ? Formatters::WifiScanJSON.new : Formatters::WifiScanHuman.new
            @stdout.puts formatter.format(networks)

            EXIT_CODE_SUCCESS
          end
        end

        private

        def parse_options
          OptionParser.new do |opts|
            opts.banner = "Usage: raygatherer wifi scan [options]"
            opts.separator ""
            opts.separator "Options:"

            add_help_option(opts)
          end.parse!(@argv)
        end

        def show_help(output = @stdout)
          output.puts "Usage: raygatherer [global options] wifi scan [options]"
          output.puts ""
          output.puts "Scan for nearby wifi networks the device could connect to as a client."
          output.puts ""
          output.puts "Options:"
          output.puts "    -h, --help                       Show this help message"
          output.puts ""
          print_global_options(output)
          output.puts ""
          output.puts "Examples:"
          output.puts "  raygatherer --host http://192.168.1.100:8080 wifi scan"
          output.puts "  raygatherer --host http://192.168.1.100:8080 --json wifi scan"
        end
      end
    end
  end
end
