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
    end

    def run
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
      subcommand = @argv.shift

      if command == "alert" && subcommand == "status"
        require_relative "commands/alert/status"
        return Commands::Alert::Status.run(@argv, stdout: @stdout, stderr: @stderr)
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

    def show_help(output = @stdout)
      output.puts "Usage: raygatherer [options] [command]"
      output.puts ""
      output.puts "Options:"
      output.puts "    -v, --version                    Show version"
      output.puts "    -h, --help                       Show this help message"
      output.puts ""
      output.puts "Commands:"
      output.puts "    alert status                     Check for active IMSI catcher alerts"
      output.puts ""
      output.puts "Run 'raygatherer COMMAND --help' for more information on a command."
    end
  end
end
