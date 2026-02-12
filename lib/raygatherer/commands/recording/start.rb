# frozen_string_literal: true

require "optparse"
require_relative "../base"

module Raygatherer
  module Commands
    module Recording
      class Start < Base
        def run
          with_error_handling do
            parse_options

            if @argv.any?
              @stderr.puts "Error: recording start does not take a name"
              next 1
            end

            @api_client.start_recording
            @stdout.puts "Recording started"
            0
          end
        end

        private

        def parse_options
          OptionParser.new do |opts|
            opts.banner = "Usage: raygatherer recording start"
            opts.separator ""
            opts.separator "Options:"

            opts.on("-h", "--help", "Show this help message") do
              show_help
              raise CLI::EarlyExit, 0
            end
          end.parse!(@argv)
        end

        def show_help(output = @stdout)
          output.puts "Usage: raygatherer [global options] recording start"
          output.puts ""
          output.puts "Starts a new recording on the device."
          output.puts ""
          output.puts "Options:"
          output.puts "    -h, --help                       Show this help message"
          output.puts ""
          output.puts "Global options (see 'raygatherer --help'):"
          output.puts "    --host, --basic-auth-user, --basic-auth-password, --verbose"
          output.puts ""
          output.puts "Examples:"
          output.puts "  raygatherer --host http://192.168.1.100:8080 recording start"
        end
      end
    end
  end
end
