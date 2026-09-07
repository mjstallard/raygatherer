# frozen_string_literal: true

require_relative "../base"

module Raygatherer
  module Commands
    module Gps
      class Set < Base
        def run
          with_error_handling do
            parse_options

            unless @argv.length == 2
              @stderr.puts "Error: latitude and longitude are required (usage: gps set LAT LON)"
              return EXIT_CODE_ERROR
            end

            lat_str, lon_str = @argv

            latitude = parse_coordinate(lat_str, "latitude")
            return EXIT_CODE_ERROR unless latitude

            longitude = parse_coordinate(lon_str, "longitude")
            return EXIT_CODE_ERROR unless longitude

            @api_client.set_gps(latitude, longitude)
            @stdout.puts "GPS position set: #{latitude}, #{longitude}"

            EXIT_CODE_SUCCESS
          end
        end

        private

        def parse_coordinate(str, label)
          Float(str)
        rescue ArgumentError
          @stderr.puts "Error: #{label} must be a number (got #{str.inspect})"
          nil
        end

        # Deliberately not using OptionParser#parse! here: a negative longitude like "-0.1"
        # looks like an unrecognized flag to it and raises OptionParser::InvalidOption. This
        # command's only "option" is help, so just scan for it directly instead.
        def parse_options
          return unless @argv.include?("-h") || @argv.include?("--help")

          show_help
          raise CLI::EarlyExit, EXIT_CODE_SUCCESS
        end

        def show_help(output = @stdout)
          output.puts "Usage: raygatherer [global options] gps set [options] LAT LON"
          output.puts ""
          output.puts "Submit a GPS position to the device, to be embedded into the current recording."
          output.puts "Requires the device's gps_mode config to be set to 'Api' (see 'config show'/'config set')."
          output.puts ""
          output.puts "Options:"
          output.puts "    -h, --help                       Show this help message"
          output.puts ""
          print_global_options(output)
          output.puts ""
          output.puts "Examples:"
          output.puts "  raygatherer --host http://192.168.1.100:8080 gps set 51.5074 -0.1278"
        end
      end
    end
  end
end
