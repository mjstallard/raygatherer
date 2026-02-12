# frozen_string_literal: true

require "optparse"

module Raygatherer
  class CLI
    # Custom exception to handle early returns without calling exit
    class EarlyExit < StandardError
      attr_reader :exit_code

      def initialize(exit_code)
        @exit_code = exit_code
        super()
      end
    end

    def self.run(argv, stdout: $stdout, stderr: $stderr)
      new(argv, stdout: stdout, stderr: stderr).run
    end

    def initialize(argv, stdout: $stdout, stderr: $stderr)
      @argv = argv
      @stdout = stdout
      @stderr = stderr
      @verbose = false
    end

    def run
      # Extract global flags BEFORE processing
      @verbose = @argv.delete("--verbose") ? true : false
      @json = @argv.delete("--json") ? true : false
      @host = extract_value_flag("--host")
      @username = extract_value_flag("--basic-auth-user")
      @password = extract_value_flag("--basic-auth-password")

      if @argv.empty?
        show_help
        return 0
      end

      # Check if first argument is a flag
      if @argv.first =~ /^-/
        parse_options
        return 0
      end

      # Route to commands
      command = @argv.shift

      if command == "stats"
        require_relative "commands/stats"
        return 1 unless require_host!
        return Commands::Stats.run(
          @argv,
          stdout: @stdout,
          stderr: @stderr,
          api_client: build_api_client,
          json: @json
        )
      end

      subcommand = @argv.shift

      if command == "alert" && subcommand == "status"
        require_relative "commands/alert/status"
        return 1 unless require_host!
        return Commands::Alert::Status.run(
          @argv,
          stdout: @stdout,
          stderr: @stderr,
          api_client: build_api_client,
          json: @json
        )
      end

      if command == "recording" && subcommand == "list"
        require_relative "commands/recording/list"
        return 1 unless require_host!
        return Commands::Recording::List.run(
          @argv,
          stdout: @stdout,
          stderr: @stderr,
          api_client: build_api_client,
          json: @json
        )
      end

      if command == "recording" && subcommand == "download"
        require_relative "commands/recording/download"
        return 1 unless require_host!
        return Commands::Recording::Download.run(
          @argv,
          stdout: @stdout,
          stderr: @stderr,
          api_client: build_api_client
        )
      end

      if command == "recording" && subcommand == "delete"
        require_relative "commands/recording/delete"
        return 1 unless require_host!
        return Commands::Recording::Delete.run(
          @argv,
          stdout: @stdout,
          stderr: @stderr,
          api_client: build_api_client
        )
      end

      # Unknown command
      @stderr.puts "Unknown command: #{[command, subcommand].compact.join(' ')}"
      show_help(@stderr)
      1
    rescue OptionParser::InvalidOption => e
      @stderr.puts e.message
      show_help(@stderr)
      1
    rescue EarlyExit => e
      e.exit_code
    end

    private

    def parse_options
      OptionParser.new do |opts|
        opts.banner = "Usage: raygatherer [options] [command]"
        opts.separator ""
        opts.separator "Options:"

        opts.on("-v", "--version", "Show version") do
          @stdout.puts "raygatherer version #{Raygatherer::VERSION}"
          raise EarlyExit, 0
        end

        opts.on("-h", "--help", "Show this help message") do
          show_help
          raise EarlyExit, 0
        end

        opts.separator ""
        opts.separator "Commands will be added in future iterations."
      end.parse!(@argv)
    end

    def require_host!
      return true if @host
      return true if @argv.include?("--help") || @argv.include?("-h")
      @stderr.puts "Error: --host is required"
      show_help(@stderr)
      false
    end

    def build_api_client
      return nil unless @host
      ApiClient.new(@host, username: @username, password: @password,
                    verbose: @verbose, stderr: @stderr)
    end

    def extract_value_flag(flag)
      index = @argv.index(flag)
      return nil unless index
      @argv.delete_at(index) # remove the flag
      @argv.delete_at(index) # remove the value (shifted into same index)
    end

    def show_help(output = @stdout)
      output.puts "Usage: raygatherer [options] [command]"
      output.puts ""
      output.puts "Options:"
      output.puts "    -v, --version                    Show version"
      output.puts "    -h, --help                       Show this help message"
      output.puts "        --verbose                    Show detailed HTTP request/response information"
      output.puts "        --host HOST                  Rayhunter host URL (required)"
      output.puts "        --basic-auth-user USER       Basic auth username"
      output.puts "        --basic-auth-password PASS   Basic auth password"
      output.puts "        --json                       Output JSON (for scripts/piping)"
      output.puts ""
      output.puts "Commands:"
      output.puts "    alert status                     Check for active IMSI catcher alerts"
      output.puts "    recording list                   List recordings on the device"
      output.puts "    recording download <name>        Download a recording from the device"
      output.puts "    recording delete <name>          Delete a recording from the device"
      output.puts "    stats                            Show device system stats"
      output.puts ""
      output.puts "Run 'raygatherer COMMAND --help' for more information on a command."
    end
  end
end
