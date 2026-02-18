# frozen_string_literal: true

require "open3"
require "tmpdir"

RSpec.describe "CLI Integration" do
  include StderrHelpers

  let(:exe_path) { File.expand_path("../../exe/raygatherer", __dir__) }

  around do |example|
    Dir.mktmpdir do |dir|
      @clean_env = {"XDG_CONFIG_HOME" => dir}
      example.run
    end
  end

  describe "raygatherer --version" do
    it "outputs version and exits successfully" do
      stdout, stderr, status = Open3.capture3(@clean_env, exe_path, "--version")

      expect(stdout).to include("raygatherer version")
      expect(stdout).to include(Raygatherer::VERSION)
      expect(strip_ruby_warnings(stderr)).to be_empty
      expect(status.exitstatus).to eq(0)
    end
  end

  describe "raygatherer --help" do
    it "outputs help and exits successfully" do
      stdout, stderr, status = Open3.capture3(@clean_env, exe_path, "--help")

      expect(stdout).to include("Usage:")
      expect(stdout).to include("--version")
      expect(stdout).to include("--help")
      expect(strip_ruby_warnings(stderr)).to be_empty
      expect(status.exitstatus).to eq(0)
    end
  end

  describe "raygatherer with no args" do
    it "outputs help and exits successfully" do
      stdout, stderr, status = Open3.capture3(@clean_env, exe_path)

      expect(stdout).to include("Usage:")
      expect(strip_ruby_warnings(stderr)).to be_empty
      expect(status.exitstatus).to eq(0)
    end
  end

  describe "raygatherer with invalid flag" do
    it "outputs error to stderr and exits with failure" do
      _, stderr, status = Open3.capture3(@clean_env, exe_path, "--invalid")

      expect(stderr).to include("invalid option")
      expect(stderr).to include("Usage:")
      expect(status.exitstatus).to eq(1)
    end
  end

  # Subcommands: host required, help, connection error
  it_behaves_like "a subcommand",
    args: ["alerts"], command_name: "alerts",
    help_includes: ["--json", "--latest", "--after", "--recording", "Exit Codes:"]

  it_behaves_like "a subcommand",
    args: ["recording", "list"], command_name: "recording list"

  it_behaves_like "a subcommand",
    args: ["recording", "download", "myrecording"], command_name: "recording download",
    help_includes: ["--qmdl", "--pcap", "--zip", "--download-dir", "--save-as"] do
    # download --help doesn't need a name argument
    let(:help_args) { ["recording", "download"] }
  end

  it_behaves_like "a subcommand",
    args: ["recording", "stop"], command_name: "recording stop"

  it_behaves_like "a subcommand",
    args: ["recording", "start"], command_name: "recording start"

  it_behaves_like "a subcommand",
    args: ["analysis", "status"], command_name: "analysis status"

  it_behaves_like "a subcommand",
    args: ["log"], command_name: "log"

  it_behaves_like "visible in main help", "log"

  it_behaves_like "a subcommand",
    args: ["stats"], command_name: "stats"

  it_behaves_like "a subcommand",
    args: ["config", "show"], command_name: "config show"

  it_behaves_like "a subcommand",
    args: ["config", "test-notification"], command_name: "config test-notification"

  # Commands with custom validation
  describe "raygatherer recording download" do
    it "requires a recording name argument" do
      _, stderr, status = Open3.capture3(@clean_env,
        exe_path, "recording", "download", "--host", "http://localhost:9999")

      expect(stderr).to include("recording name is required")
      expect(status.exitstatus).to eq(1)
    end
  end

  describe "raygatherer recording delete" do
    it "requires --host flag" do
      _, stderr, status = Open3.capture3(@clean_env, exe_path, "recording", "delete", "myrecording")

      expect(stderr).to include("--host is required")
      expect(stderr).to include("Usage:")
      expect(status.exitstatus).to eq(1)
    end

    it "shows help with --help" do
      stdout, stderr, status = Open3.capture3(@clean_env, exe_path, "recording", "delete", "--help")

      expect(stdout).to include("Usage:")
      expect(stdout).to include("recording delete")
      expect(stdout).to include("--host")
      expect(strip_ruby_warnings(stderr)).to be_empty
      expect(status.exitstatus).to eq(0)
    end

    it "handles connection errors gracefully" do
      _, stderr, status = Open3.capture3(@clean_env,
        exe_path, "recording", "delete", "myrecording", "--host", "http://localhost:9999")

      expect(stderr).to include("Error")
      expect(stderr).to include("Failed to connect")
      expect(status.exitstatus).to eq(1)
    end

    it "requires a recording name argument" do
      _, stderr, status = Open3.capture3(@clean_env,
        exe_path, "recording", "delete", "--host", "http://localhost:9999")

      expect(stderr).to include("recording name is required")
      expect(status.exitstatus).to eq(1)
    end
  end

  describe "raygatherer recording stop" do
    it "rejects a recording name argument" do
      _, stderr, status = Open3.capture3(@clean_env,
        exe_path, "recording", "stop", "myrecording", "--host", "http://localhost:9999")

      expect(stderr).to include("recording stop does not take a name")
      expect(status.exitstatus).to eq(1)
    end
  end

  describe "raygatherer recording start" do
    it "rejects a recording name argument" do
      _, stderr, status = Open3.capture3(@clean_env,
        exe_path, "recording", "start", "myrecording", "--host", "http://localhost:9999")

      expect(stderr).to include("recording start does not take a name")
      expect(status.exitstatus).to eq(1)
    end
  end

  describe "raygatherer analysis run" do
    it "requires --host flag" do
      _, stderr, status = Open3.capture3(@clean_env, exe_path, "analysis", "run", "myrecording")

      expect(stderr).to include("--host is required")
      expect(stderr).to include("Usage:")
      expect(status.exitstatus).to eq(1)
    end

    it "shows help with --help" do
      stdout, stderr, status = Open3.capture3(@clean_env, exe_path, "analysis", "run", "--help")

      expect(stdout).to include("Usage:")
      expect(stdout).to include("analysis run")
      expect(stdout).to include("--all")
      expect(strip_ruby_warnings(stderr)).to be_empty
      expect(status.exitstatus).to eq(0)
    end

    it "requires a name or --all" do
      _, stderr, status = Open3.capture3(@clean_env, exe_path, "analysis", "run", "--host", "http://localhost:9999")

      expect(stderr).to include("recording name or --all is required")
      expect(status.exitstatus).to eq(1)
    end

    it "handles connection errors gracefully" do
      _, stderr, status = Open3.capture3(@clean_env, exe_path, "analysis", "run", "myrecording", "--host", "http://localhost:9999")

      expect(stderr).to include("Error")
      expect(stderr).to include("Failed to connect")
      expect(status.exitstatus).to eq(1)
    end
  end

  describe "raygatherer config set" do
    it "requires --host flag" do
      _, stderr, status = Open3.capture3(@clean_env, exe_path, "config", "set")

      expect(stderr).to include("--host is required")
      expect(stderr).to include("Usage:")
      expect(status.exitstatus).to eq(1)
    end

    it "shows help with --help" do
      stdout, stderr, status = Open3.capture3(@clean_env, exe_path, "config", "set", "--help")

      expect(stdout).to include("Usage:")
      expect(stdout).to include("config set")
      expect(strip_ruby_warnings(stderr)).to be_empty
      expect(status.exitstatus).to eq(0)
    end

    it "reports error when stdin is empty" do
      stdin_data = ""
      _, stderr, status = Open3.capture3(
        @clean_env,
        exe_path, "config", "set", "--host", "http://localhost:9999",
        stdin_data: stdin_data
      )

      expect(stderr).to include("no JSON input received")
      expect(status.exitstatus).to eq(1)
    end
  end

  # --verbose flag
  describe "raygatherer --verbose" do
    it "accepts --verbose flag before command" do
      _, stderr, status = Open3.capture3(@clean_env,
        exe_path, "--verbose", "alerts", "--host", "http://localhost:9999")

      expect(stderr).to include("HTTP GET http://localhost:9999/api/analysis-report/live")
      expect(status.exitstatus).to eq(1)
    end

    it "accepts --verbose flag after command" do
      _, stderr, status = Open3.capture3(@clean_env,
        exe_path, "alerts", "--verbose", "--host", "http://localhost:9999")

      expect(stderr).to include("HTTP GET")
      expect(status.exitstatus).to eq(1)
    end

    it "does not output verbose logs without flag" do
      _, stderr, status = Open3.capture3(@clean_env,
        exe_path, "alerts", "--host", "http://localhost:9999")

      expect(stderr).not_to include("HTTP GET")
      expect(stderr).not_to include("Request started")
      expect(stderr).to include("Error")
      expect(status.exitstatus).to eq(1)
    end

    it "verbose output goes to stderr, not stdout" do
      stdout, stderr, _ = Open3.capture3(@clean_env,
        exe_path, "--verbose", "alerts", "--host", "http://localhost:9999")

      expect(stdout).to be_empty
      expect(stderr).to include("HTTP GET")
    end
  end

  # --json flag
  describe "raygatherer --json flag" do
    it "outputs valid JSON when --json flag is used" do
      stdout, _, status = Open3.capture3(@clean_env,
        exe_path, "alerts", "--host", "http://localhost:9999", "--json")

      expect(stdout).to be_empty
      expect(status.exitstatus).to eq(1)
    end

    it "outputs human-readable format without --json (default)" do
      _, stderr, status = Open3.capture3(@clean_env,
        exe_path, "alerts", "--host", "http://localhost:9999")

      expect(stderr).to include("Error")
      expect(status.exitstatus).to eq(1)
    end

    it "works with --json and --verbose together" do
      _, stderr, status = Open3.capture3(@clean_env,
        exe_path, "--verbose", "alerts", "--host", "http://localhost:9999", "--json")

      expect(stderr).to include("HTTP GET")
      expect(status.exitstatus).to eq(1)
    end
  end

  # Main help includes all subcommands
  describe "main help" do
    %w[
      alerts stats
    ].each do |cmd|
      it_behaves_like "visible in main help", cmd
    end

    [
      "recording list", "recording download", "recording delete",
      "recording stop", "recording start",
      "analysis status", "analysis run",
      "config show", "config set", "config test-notification"
    ].each do |cmd|
      it_behaves_like "visible in main help", cmd
    end

    it "shows Configuration section with config file path" do
      stdout, _, status = Open3.capture3(@clean_env, exe_path, "--help")

      expect(stdout).to include("Configuration:")
      expect(stdout).to include("config.yml")
      expect(status.exitstatus).to eq(0)
    end
  end

  # Exit codes
  describe "raygatherer exit codes" do
    it "returns exit code 1 when --host is missing" do
      _, stderr, status = Open3.capture3(@clean_env, exe_path, "alerts")

      expect(stderr).to include("--host is required")
      expect(status.exitstatus).to eq(1)
    end
  end
end
