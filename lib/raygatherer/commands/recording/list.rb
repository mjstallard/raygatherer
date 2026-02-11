# frozen_string_literal: true

require "optparse"
require_relative "../../formatters/recording_list_json"
require_relative "../../formatters/recording_list_human"

module Raygatherer
  module Commands
    module Recording
      class List
        def self.run(argv, stdout: $stdout, stderr: $stderr, verbose: false,
                     host: nil, username: nil, password: nil, json: false)
          new(argv, stdout: stdout, stderr: stderr, verbose: verbose,
              host: host, username: username, password: password, json: json).run
        end

        def initialize(argv, stdout: $stdout, stderr: $stderr, verbose: false,
                       host: nil, username: nil, password: nil, json: false)
          @argv = argv
          @stdout = stdout
          @stderr = stderr
          @verbose = verbose
          @host = host
          @username = username
          @password = password
          @json = json
        end

        def run
          parse_options

          unless @host
            @stderr.puts "Error: --host is required"
            show_help(@stderr)
            return 1
          end

          api_client = ApiClient.new(
            @host,
            username: @username,
            password: @password,
            verbose: @verbose,
            stderr: @stderr
          )
          manifest = api_client.fetch_manifest

          formatter = @json ? Formatters::RecordingListJSON.new : Formatters::RecordingListHuman.new
          @stdout.puts formatter.format(manifest)

          0
        rescue CLI::EarlyExit
          raise
        rescue ApiClient::ConnectionError, ApiClient::ApiError, ApiClient::ParseError => e
          @stderr.puts "Error: #{e.message}"
          1
        rescue => e
          @stderr.puts "Error: #{e.message}"
          1
        end

        private

        def parse_options
          OptionParser.new do |opts|
            opts.banner = "Usage: raygatherer recording list [options]"
            opts.separator ""
            opts.separator "Options:"

            opts.on("-h", "--help", "Show this help message") do
              show_help
              raise CLI::EarlyExit, 0
            end
          end.parse!(@argv)
        end

        def show_help(output = @stdout)
          output.puts "Usage: raygatherer [global options] recording list [options]"
          output.puts ""
          output.puts "Options:"
          output.puts "    -h, --help                       Show this help message"
          output.puts ""
          output.puts "Global options (see 'raygatherer --help'):"
          output.puts "    --host, --basic-auth-user, --basic-auth-password, --json, --verbose"
          output.puts ""
          output.puts "Examples:"
          output.puts "  raygatherer --host http://192.168.1.100:8080 recording list"
          output.puts "  raygatherer --host http://192.168.1.100:8080 --json recording list"
        end
      end
    end
  end
end
