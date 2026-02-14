# frozen_string_literal: true

require "json"
require "optparse"
require_relative "../base"

module Raygatherer
  module Commands
    module Config
      class Set < Base
        def initialize(argv, stdout: $stdout, stderr: $stderr, api_client: nil, stdin: $stdin, **_kwargs)
          super(argv, stdout: stdout, stderr: stderr, api_client: api_client)
          @stdin = stdin
        end

        def run
          with_error_handling do
            parse_options

            json_input = @stdin.read.strip

            if json_input.empty?
              @stderr.puts "Error: no JSON input received on stdin"
              return 1
            end

            begin
              ::JSON.parse(json_input)
            rescue ::JSON::ParserError => e
              @stderr.puts "Error: invalid JSON input: #{e.message}"
              return 1
            end

            @api_client.set_config(json_input)
            @stdout.puts "Configuration updated successfully."

            0
          end
        end

        private

        def parse_options
          OptionParser.new do |opts|
            opts.banner = "Usage: raygatherer config set [options]"
            opts.separator ""
            opts.separator "Reads JSON configuration from stdin."
            opts.separator ""
            opts.separator "Options:"

            opts.on("-h", "--help", "Show this help message") do
              show_help
              raise CLI::EarlyExit, 0
            end
          end.parse!(@argv)
        end

        def show_help(output = @stdout)
          output.puts "Usage: raygatherer [global options] config set [options]"
          output.puts ""
          output.puts "Reads JSON configuration from stdin and sends it to the device."
          output.puts ""
          output.puts "Options:"
          output.puts "    -h, --help                       Show this help message"
          output.puts ""
          print_global_options(output)
          output.puts ""
          output.puts "Examples:"
          output.puts "  raygatherer --host http://rayhunter --json config show | \\"
          output.puts "    jq '.analyzers.null_cipher = false' | \\"
          output.puts "    raygatherer --host http://rayhunter config set"
        end
      end
    end
  end
end
