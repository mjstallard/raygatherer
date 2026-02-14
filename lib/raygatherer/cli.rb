# frozen_string_literal: true

require "optparse"
require_relative "config"

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

    ROUTES = {
      ["stats", nil] => {file: "commands/stats", klass: "Commands::Stats", json: true},
      ["alerts", nil] => {file: "commands/alerts", klass: "Commands::Alerts", json: true},
      ["recording", "list"] => {file: "commands/recording/list", klass: "Commands::Recording::List", json: true},
      ["recording", "download"] => {file: "commands/recording/download", klass: "Commands::Recording::Download", json: false},
      ["recording", "delete"] => {file: "commands/recording/delete", klass: "Commands::Recording::Delete", json: false},
      ["recording", "stop"] => {file: "commands/recording/stop", klass: "Commands::Recording::Stop", json: false},
      ["recording", "start"] => {file: "commands/recording/start", klass: "Commands::Recording::Start", json: false},
      ["analysis", "status"] => {file: "commands/analysis/status", klass: "Commands::Analysis::Status", json: true},
      ["analysis", "run"] => {file: "commands/analysis/run", klass: "Commands::Analysis::Run", json: true},
      ["config", "show"] => {file: "commands/config/show", klass: "Commands::Config::Show", json: true}
    }.freeze

    def self.run(argv, stdout: $stdout, stderr: $stderr, config: Config.new)
      new(argv, stdout: stdout, stderr: stderr, config: config).run
    end

    def initialize(argv, stdout: $stdout, stderr: $stderr, config: Config.new)
      @argv = argv
      @stdout = stdout
      @stderr = stderr
      @config = config
      @verbose = false
    end

    def run
      # Extract global flags BEFORE processing
      cli_verbose = @argv.delete("--verbose") ? true : nil
      cli_json = @argv.delete("--json") ? true : nil
      cli_host = extract_value_flag("--host")
      cli_username = extract_value_flag("--basic-auth-user")
      cli_password = extract_value_flag("--basic-auth-password")

      config_values = @config.load

      @verbose = cli_verbose.nil? ? (config_values["verbose"] || false) : cli_verbose
      @json = cli_json.nil? ? (config_values["json"] || false) : cli_json
      @host = cli_host || config_values["host"]
      @username = cli_username || config_values["basic_auth_user"]
      @password = cli_password || config_values["basic_auth_password"]

      if @argv.empty?
        show_help
        return 0
      end

      # Check if first argument is a flag
      if /^-/.match?(@argv.first)
        parse_options
        return 0
      end

      # Route to commands
      command = @argv.shift
      subcommand = @argv.first

      route = ROUTES[[command, subcommand]]
      if route
        @argv.shift # consume subcommand
      else
        route = ROUTES[[command, nil]]
      end

      unless route
        @stderr.puts "Unknown command: #{[command, subcommand].compact.join(" ")}"
        show_help(@stderr)
        return 1
      end

      require_relative route[:file]
      return 1 unless require_host!

      kwargs = {stdout: @stdout, stderr: @stderr, api_client: build_api_client}
      kwargs[:json] = @json if route[:json]

      resolve_class(route[:klass]).run(@argv, **kwargs)
    rescue Config::ConfigError => e
      @stderr.puts "Error: #{e.message}"
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

    def resolve_class(name)
      name.split("::").reduce(Raygatherer) { |mod, part| mod.const_get(part) }
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
      output.puts "    alerts                           Check for active IMSI catcher alerts"
      output.puts "    recording list                   List recordings on the device"
      output.puts "    recording download <name>        Download a recording from the device"
      output.puts "    recording delete <name>          Delete a recording from the device"
      output.puts "    recording stop                   Stop the current recording"
      output.puts "    recording start                  Start a new recording"
      output.puts "    analysis status                   Show analysis queue status"
      output.puts "    analysis run <name>               Queue a recording for analysis"
      output.puts "    analysis run --all                Queue all recordings for analysis"
      output.puts "    config show                       Show device configuration"
      output.puts "    stats                            Show device system stats"
      output.puts ""
      output.puts "Configuration:"
      output.puts "    Config file: ~/.config/raygatherer/config.yml"
      output.puts "    (or $XDG_CONFIG_HOME/raygatherer/config.yml)"
      output.puts ""
      output.puts "    Supported keys: host, basic_auth_user, basic_auth_password, json, verbose"
      output.puts "    CLI flags always override config file values."
      output.puts "    Note: config file may contain credentials; consider restricting file permissions."
      output.puts ""
      output.puts "Run 'raygatherer COMMAND --help' for more information on a command."
    end
  end
end
