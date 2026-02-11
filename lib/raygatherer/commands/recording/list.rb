# frozen_string_literal: true

require "optparse"
require_relative "../../formatters/recording_list_json"
require_relative "../../formatters/recording_list_human"

module Raygatherer
  module Commands
    module Recording
      class List
        def self.run(argv, stdout: $stdout, stderr: $stderr, verbose: false)
          new(argv, stdout: stdout, stderr: stderr, verbose: verbose).run
        end

        def initialize(argv, stdout: $stdout, stderr: $stderr, verbose: false)
          @argv = argv
          @stdout = stdout
          @stderr = stderr
          @verbose = verbose
          @host = nil
          @username = nil
          @password = nil
          @json = false
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

            opts.on("--host HOST", "Rayhunter host URL (required)") do |h|
              @host = h
            end

            opts.on("--basic-auth-user USER", "Basic auth username") do |u|
              @username = u
            end

            opts.on("--basic-auth-password PASS", "Basic auth password") do |p|
              @password = p
            end

            opts.on("--json", "Output JSON instead of human-readable format") do
              @json = true
            end

            opts.on("-h", "--help", "Show this help message") do
              show_help
              raise CLI::EarlyExit, 0
            end
          end.parse!(@argv)
        end

        def show_help(output = @stdout)
          output.puts "Usage: raygatherer recording list [options]"
          output.puts ""
          output.puts "Options:"
          output.puts "    --host HOST                      Rayhunter host URL (required)"
          output.puts "    --basic-auth-user USER           Basic auth username"
          output.puts "    --basic-auth-password PASS       Basic auth password"
          output.puts "    --json                           Output JSON (for scripts/piping)"
          output.puts "    -h, --help                       Show this help message"
          output.puts ""
          output.puts "Examples:"
          output.puts "  raygatherer recording list --host http://192.168.1.100:8080"
          output.puts "  raygatherer recording list --host http://192.168.1.100:8080 --json | jq"
        end
      end
    end
  end
end
