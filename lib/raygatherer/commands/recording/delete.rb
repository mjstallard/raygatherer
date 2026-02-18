# frozen_string_literal: true

require "optparse"
require_relative "../base"

module Raygatherer
  module Commands
    module Recording
      class Delete < Base
        def initialize(argv, stdout: $stdout, stderr: $stderr, api_client: nil, stdin: $stdin, **_kwargs)
          super(argv, stdout: stdout, stderr: stderr, api_client: api_client)
          @stdin = stdin
          @all = false
          @force = false
        end

        def run
          with_error_handling do
            parse_options

            if @all && !@argv.empty?
              @stderr.puts "Error: cannot specify both a recording name and --all"
              next EXIT_CODE_ERROR
            end

            if @all
              delete_all
            else
              delete_named
            end
          end
        end

        private

        def delete_all
          unless @force
            @stderr.print "Warning: This will permanently delete ALL recordings!\nAre you sure? [y/N]: "
            response = @stdin.gets&.strip&.downcase || ""
            unless response == "y" || response == "yes"
              @stderr.puts "Aborted."
              return EXIT_CODE_ERROR
            end
          end
          @api_client.delete_all_recordings
          @stdout.puts "Deleted all recordings."
          EXIT_CODE_SUCCESS
        end

        def delete_named
          name = @argv.shift
          unless name
            @stderr.puts "Error: recording name or --all is required"
            return EXIT_CODE_ERROR
          end
          @api_client.delete_recording(name)
          @stdout.puts "Deleted recording: #{name}"
          EXIT_CODE_SUCCESS
        end

        def parse_options
          OptionParser.new do |opts|
            opts.banner = "Usage: raygatherer recording delete <name> | --all [--force]"
            opts.separator ""
            opts.separator "Options:"

            opts.on("--all", "Delete all recordings (prompts for confirmation)") do
              @all = true
            end

            opts.on("-f", "--force", "Skip confirmation prompt (use with --all)") do
              @force = true
            end

            opts.on("-h", "--help", "Show this help message") do
              show_help
              raise CLI::EarlyExit, EXIT_CODE_SUCCESS
            end
          end.parse!(@argv)
        end

        def show_help(output = @stdout)
          output.puts "Usage: raygatherer [global options] recording delete <name>"
          output.puts "       raygatherer [global options] recording delete --all [--force]"
          output.puts ""
          output.puts "Options:"
          output.puts "    --all                            Delete all recordings (prompts for confirmation)"
          output.puts "    -f, --force                      Skip confirmation prompt (use with --all)"
          output.puts "    -h, --help                       Show this help message"
          output.puts ""
          print_global_options(output)
          output.puts ""
          output.puts "Examples:"
          output.puts "  raygatherer --host http://192.168.1.100:8080 recording delete 1738950000"
          output.puts "  raygatherer --host http://192.168.1.100:8080 recording delete --all"
          output.puts "  raygatherer --host http://192.168.1.100:8080 recording delete --all --force"
          output.puts "  echo y | raygatherer --host http://192.168.1.100:8080 recording delete --all"
        end
      end
    end
  end
end
