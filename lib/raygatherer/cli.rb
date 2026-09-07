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
      ["log", nil] => Commands::Log,
      ["stats", nil] => Commands::Stats,
      ["alerts", nil] => Commands::Alerts,
      ["recording", "list"] => Commands::Recording::List,
      ["recording", "download"] => Commands::Recording::Download,
      ["recording", "delete"] => Commands::Recording::Delete,
      ["recording", "stop"] => Commands::Recording::Stop,
      ["recording", "start"] => Commands::Recording::Start,
      ["analysis", "status"] => Commands::Analysis::Status,
      ["analysis", "run"] => Commands::Analysis::Run,
      ["analysis", "report"] => Commands::Analysis::Report,
      ["config", "show"] => Commands::Config::Show,
      ["config", "set"] => Commands::Config::Set,
      ["config", "test-notification"] => Commands::Config::TestNotification,
      ["debug", "display-state"] => Commands::Debug::DisplayState,
      ["time", "show"] => Commands::Time::Show,
      ["time", "sync"] => Commands::Time::Sync,
      ["update", "status"] => Commands::Update::Status,
      ["gps", "show"] => Commands::Gps::Show,
      ["gps", "set"] => Commands::Gps::Set,
      ["wifi", "show"] => Commands::Wifi::Show,
      ["wifi", "scan"] => Commands::Wifi::Scan
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
      cli_verbose = extract_boolean_flag("--verbose")
      cli_json = extract_boolean_flag("--json")
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
        return Commands::EXIT_CODE_SUCCESS
      end

      # Check if first argument is a flag
      if /^-/.match?(@argv.first)
        parse_options
        return Commands::EXIT_CODE_SUCCESS
      end

      # Route to commands
      command = @argv.shift
      subcommand = @argv.first

      klass = ROUTES[[command, subcommand]]
      if klass
        @argv.shift # consume subcommand
      else
        klass = ROUTES[[command, nil]]
      end

      unless klass
        @stderr.puts "Unknown command: #{[command, subcommand].compact.join(" ")}"
        show_help(@stderr)
        return Commands::EXIT_CODE_ERROR
      end

      return Commands::EXIT_CODE_ERROR unless require_host!

      kwargs = {stdout: @stdout, stderr: @stderr, api_client: build_api_client}
      kwargs[:json] = @json if klass.supports_json?

      klass.run(@argv, **kwargs)
    rescue Config::ConfigError => e
      @stderr.puts "Error: #{e.message}"
      Commands::EXIT_CODE_ERROR
    rescue OptionParser::InvalidOption => e
      @stderr.puts e.message
      show_help(@stderr)
      Commands::EXIT_CODE_ERROR
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
          raise EarlyExit, Commands::EXIT_CODE_SUCCESS
        end

        opts.on("-h", "--help", "Show this help message") do
          show_help
          raise EarlyExit, Commands::EXIT_CODE_SUCCESS
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

    def extract_boolean_flag(flag)
      @argv.delete(flag) ? true : nil
    end

    def extract_value_flag(flag)
      index = @argv.index(flag)
      return nil unless index
      @argv.slice!(index, 2)&.last
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
      output.puts "    analysis status                  Show analysis queue status"
      output.puts "    analysis run <name>              Queue a recording for analysis"
      output.puts "    analysis run --all               Queue all recordings for analysis"
      output.puts "    analysis report <name>           Show the full analysis report for a recording"
      output.puts "    config show                      Show device configuration"
      output.puts "    config set                       Update device configuration (reads JSON from stdin)"
      output.puts "    config test-notification         Send a test notification"
      output.puts "    debug display-state STATE        Set device display state (recording, paused, warning)"
      output.puts "    time show                        Show device time (system, adjusted, offset)"
      output.puts "    time sync                        Sync device clock to this machine's time"
      output.puts "    update status                    Show rayhunter daemon update status"
      output.puts "    gps show                         Show last known GPS position"
      output.puts "    gps set LAT LON                  Submit a GPS position (requires gps_mode=Api on device)"
      output.puts "    wifi show                        Show wifi client connection status"
      output.puts "    wifi scan                        Scan for available wifi networks"
      output.puts "    log                              Download the device log"
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
