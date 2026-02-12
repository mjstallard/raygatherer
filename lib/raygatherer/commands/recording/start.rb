# frozen_string_literal: true

require "optparse"

module Raygatherer
  module Commands
    module Recording
      class Start
        def self.run(argv, stdout: $stdout, stderr: $stderr, api_client: nil)
          new(argv, stdout: stdout, stderr: stderr, api_client: api_client).run
        end

        def initialize(argv, stdout: $stdout, stderr: $stderr, api_client: nil)
          @argv = argv
          @stdout = stdout
          @stderr = stderr
          @api_client = api_client
        end

        def run
          parse_options

          if @argv.any?
            @stderr.puts "Error: recording start does not take a name"
            return 1
          end

          @api_client.start_recording
          @stdout.puts "Recording started"
          0
        rescue CLI::EarlyExit
          raise
        rescue ApiClient::ConnectionError, ApiClient::ApiError => e
          @stderr.puts "Error: #{e.message}"
          1
        rescue => e
          @stderr.puts "Error: #{e.message}"
          1
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
