# frozen_string_literal: true

require "open3"

RSpec.describe "CLI Integration" do
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
      expect(stderr).to be_empty
      expect(status.exitstatus).to eq(0)
    end
  end

  describe "raygatherer --help" do
    it "outputs help and exits successfully" do
      stdout, stderr, status = Open3.capture3(@clean_env, exe_path, "--help")

      expect(stdout).to include("Usage:")
      expect(stdout).to include("--version")
      expect(stdout).to include("--help")
      expect(stderr).to be_empty
      expect(status.exitstatus).to eq(0)
    end
  end

  describe "raygatherer with no args" do
    it "outputs help and exits successfully" do
      stdout, stderr, status = Open3.capture3(@clean_env, exe_path)

      expect(stdout).to include("Usage:")
      expect(stderr).to be_empty
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

  describe "raygatherer alerts" do
    let(:host) { "http://localhost:8080" }

    it "requires --host flag" do
      _, stderr, status = Open3.capture3(@clean_env, exe_path, "alerts")

      expect(stderr).to include("--host is required")
      expect(stderr).to include("Usage:")
      expect(status.exitstatus).to eq(1)
    end

    it "shows help with --help" do
      stdout, stderr, status = Open3.capture3(@clean_env, exe_path, "alerts", "--help")

      expect(stdout).to include("Usage:")
      expect(stdout).to include("--host")
      expect(stderr).to be_empty
      expect(status.exitstatus).to eq(0)
    end

    it "handles connection errors gracefully" do
      # This will fail to connect since no server is running
      _, stderr, status = Open3.capture3(@clean_env, exe_path, "alerts", "--host", host)

      expect(stderr).to include("Error")
      expect(stderr).to include("Failed to connect")
      expect(status.exitstatus).to eq(1)
    end

    # Note: Full end-to-end tests with HTTP responses would require a running
    # rayhunter instance or a test HTTP server. Those scenarios are covered by
    # unit tests with mocked HTTP responses.
  end

  describe "raygatherer --verbose" do
    it "accepts --verbose flag before command" do
      _, stderr, status = Open3.capture3(@clean_env,
        exe_path, "--verbose", "alerts", "--host", "http://localhost:9999")

      # Will fail to connect, but should show verbose output
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
      expect(stderr).to include("Error") # Regular error message
      expect(status.exitstatus).to eq(1)
    end

    it "verbose output goes to stderr, not stdout" do
      stdout, stderr, _ = Open3.capture3(@clean_env,
        exe_path, "--verbose", "alerts", "--host", "http://localhost:9999")

      expect(stdout).to be_empty # No verbose in stdout
      expect(stderr).to include("HTTP GET") # Verbose in stderr
    end
  end

  describe "raygatherer --json flag" do
    it "outputs valid JSON when --json flag is used" do
      # This will fail to connect, but tests flag acceptance
      stdout, _, status = Open3.capture3(@clean_env,
        exe_path, "alerts", "--host", "http://localhost:9999", "--json")

      expect(stdout).to be_empty  # Error case, no output to stdout
      expect(status.exitstatus).to eq(1)  # Generic error
    end

    it "outputs human-readable format without --json (default)" do
      _, stderr, status = Open3.capture3(@clean_env,
        exe_path, "alerts", "--host", "http://localhost:9999")

      expect(stderr).to include("Error")  # Human error message
      expect(status.exitstatus).to eq(1)  # Generic error
    end

    it "works with --json and --verbose together" do
      _, stderr, status = Open3.capture3(@clean_env,
        exe_path, "--verbose", "alerts", "--host", "http://localhost:9999", "--json")

      # Verbose logs to stderr
      expect(stderr).to include("HTTP GET")
      # JSON would go to stdout (but connection fails)
      expect(status.exitstatus).to eq(1)  # Generic error
    end

    it "shows --json in help text" do
      stdout, _, status = Open3.capture3(@clean_env,
        exe_path, "alerts", "--help")

      expect(stdout).to include("--json")
      expect(stdout).to include("Exit Codes:")
      expect(status.exitstatus).to eq(0)
    end

    it "shows --latest in help text" do
      stdout, _, status = Open3.capture3(@clean_env,
        exe_path, "alerts", "--help")

      expect(stdout).to include("--latest")
      expect(status.exitstatus).to eq(0)
    end

    it "shows --after in help text" do
      stdout, _, status = Open3.capture3(@clean_env,
        exe_path, "alerts", "--help")

      expect(stdout).to include("--after")
      expect(status.exitstatus).to eq(0)
    end
  end

  describe "raygatherer recording list" do
    it "requires --host flag" do
      _, stderr, status = Open3.capture3(@clean_env, exe_path, "recording", "list")

      expect(stderr).to include("--host is required")
      expect(stderr).to include("Usage:")
      expect(status.exitstatus).to eq(1)
    end

    it "shows help with --help" do
      stdout, stderr, status = Open3.capture3(@clean_env, exe_path, "recording", "list", "--help")

      expect(stdout).to include("Usage:")
      expect(stdout).to include("recording list")
      expect(stdout).to include("--host")
      expect(stderr).to be_empty
      expect(status.exitstatus).to eq(0)
    end

    it "handles connection errors gracefully" do
      _, stderr, status = Open3.capture3(@clean_env, exe_path, "recording", "list", "--host", "http://localhost:9999")

      expect(stderr).to include("Error")
      expect(stderr).to include("Failed to connect")
      expect(status.exitstatus).to eq(1)
    end
  end

  describe "raygatherer recording download" do
    it "requires --host flag" do
      _, stderr, status = Open3.capture3(@clean_env, exe_path, "recording", "download", "myrecording")

      expect(stderr).to include("--host is required")
      expect(stderr).to include("Usage:")
      expect(status.exitstatus).to eq(1)
    end

    it "shows help with --help" do
      stdout, stderr, status = Open3.capture3(@clean_env, exe_path, "recording", "download", "--help")

      expect(stdout).to include("Usage:")
      expect(stdout).to include("recording download")
      expect(stdout).to include("--qmdl")
      expect(stdout).to include("--pcap")
      expect(stdout).to include("--zip")
      expect(stdout).to include("--download-dir")
      expect(stdout).to include("--save-as")
      expect(stderr).to be_empty
      expect(status.exitstatus).to eq(0)
    end

    it "handles connection errors gracefully" do
      _, stderr, status = Open3.capture3(@clean_env,
        exe_path, "recording", "download", "myrecording", "--host", "http://localhost:9999")

      expect(stderr).to include("Error")
      expect(stderr).to include("Failed to connect")
      expect(status.exitstatus).to eq(1)
    end

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
      expect(stderr).to be_empty
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
    it "requires --host flag" do
      _, stderr, status = Open3.capture3(@clean_env, exe_path, "recording", "stop")

      expect(stderr).to include("--host is required")
      expect(stderr).to include("Usage:")
      expect(status.exitstatus).to eq(1)
    end

    it "shows help with --help" do
      stdout, stderr, status = Open3.capture3(@clean_env, exe_path, "recording", "stop", "--help")

      expect(stdout).to include("Usage:")
      expect(stdout).to include("recording stop")
      expect(stdout).to include("--host")
      expect(stderr).to be_empty
      expect(status.exitstatus).to eq(0)
    end

    it "handles connection errors gracefully" do
      _, stderr, status = Open3.capture3(@clean_env,
        exe_path, "recording", "stop", "--host", "http://localhost:9999")

      expect(stderr).to include("Error")
      expect(stderr).to include("Failed to connect")
      expect(status.exitstatus).to eq(1)
    end

    it "rejects a recording name argument" do
      _, stderr, status = Open3.capture3(@clean_env,
        exe_path, "recording", "stop", "myrecording", "--host", "http://localhost:9999")

      expect(stderr).to include("recording stop does not take a name")
      expect(status.exitstatus).to eq(1)
    end
  end

  describe "raygatherer recording start" do
    it "requires --host flag" do
      _, stderr, status = Open3.capture3(@clean_env, exe_path, "recording", "start")

      expect(stderr).to include("--host is required")
      expect(stderr).to include("Usage:")
      expect(status.exitstatus).to eq(1)
    end

    it "shows help with --help" do
      stdout, stderr, status = Open3.capture3(@clean_env, exe_path, "recording", "start", "--help")

      expect(stdout).to include("Usage:")
      expect(stdout).to include("recording start")
      expect(stdout).to include("--host")
      expect(stderr).to be_empty
      expect(status.exitstatus).to eq(0)
    end

    it "handles connection errors gracefully" do
      _, stderr, status = Open3.capture3(@clean_env,
        exe_path, "recording", "start", "--host", "http://localhost:9999")

      expect(stderr).to include("Error")
      expect(stderr).to include("Failed to connect")
      expect(status.exitstatus).to eq(1)
    end

    it "rejects a recording name argument" do
      _, stderr, status = Open3.capture3(@clean_env,
        exe_path, "recording", "start", "myrecording", "--host", "http://localhost:9999")

      expect(stderr).to include("recording start does not take a name")
      expect(status.exitstatus).to eq(1)
    end
  end

  describe "raygatherer help includes recording download" do
    it "shows recording download in help output" do
      stdout, _, status = Open3.capture3(@clean_env, exe_path, "--help")

      expect(stdout).to include("recording download")
      expect(status.exitstatus).to eq(0)
    end
  end

  describe "raygatherer help includes recording list" do
    it "shows recording list in help output" do
      stdout, _, status = Open3.capture3(@clean_env, exe_path, "--help")

      expect(stdout).to include("recording list")
      expect(status.exitstatus).to eq(0)
    end
  end

  describe "raygatherer help includes recording delete" do
    it "shows recording delete in help output" do
      stdout, _, status = Open3.capture3(@clean_env, exe_path, "--help")

      expect(stdout).to include("recording delete")
      expect(status.exitstatus).to eq(0)
    end
  end

  describe "raygatherer help includes recording stop" do
    it "shows recording stop in help output" do
      stdout, _, status = Open3.capture3(@clean_env, exe_path, "--help")

      expect(stdout).to include("recording stop")
      expect(status.exitstatus).to eq(0)
    end
  end

  describe "raygatherer help includes recording start" do
    it "shows recording start in help output" do
      stdout, _, status = Open3.capture3(@clean_env, exe_path, "--help")

      expect(stdout).to include("recording start")
      expect(status.exitstatus).to eq(0)
    end
  end

  describe "raygatherer stats" do
    it "requires --host flag" do
      _, stderr, status = Open3.capture3(@clean_env, exe_path, "stats")

      expect(stderr).to include("--host is required")
      expect(stderr).to include("Usage:")
      expect(status.exitstatus).to eq(1)
    end

    it "shows help with --help" do
      stdout, stderr, status = Open3.capture3(@clean_env, exe_path, "stats", "--help")

      expect(stdout).to include("Usage:")
      expect(stdout).to include("stats")
      expect(stdout).to include("--host")
      expect(stderr).to be_empty
      expect(status.exitstatus).to eq(0)
    end

    it "handles connection errors gracefully" do
      _, stderr, status = Open3.capture3(@clean_env, exe_path, "stats", "--host", "http://localhost:9999")

      expect(stderr).to include("Error")
      expect(stderr).to include("Failed to connect")
      expect(status.exitstatus).to eq(1)
    end
  end

  describe "raygatherer help includes stats" do
    it "shows stats in help output" do
      stdout, _, status = Open3.capture3(@clean_env, exe_path, "--help")

      expect(stdout).to include("stats")
      expect(status.exitstatus).to eq(0)
    end
  end

  describe "raygatherer help includes Configuration section" do
    it "shows Configuration section with config file path" do
      stdout, _, status = Open3.capture3(@clean_env, exe_path, "--help")

      expect(stdout).to include("Configuration:")
      expect(stdout).to include("config.yml")
      expect(status.exitstatus).to eq(0)
    end
  end

  describe "raygatherer exit codes" do
    it "returns exit code 1 when --host is missing" do
      _, stderr, status = Open3.capture3(@clean_env,
        exe_path, "alerts")

      expect(stderr).to include("--host is required")
      expect(status.exitstatus).to eq(1)  # Generic error
    end

    # Note: Testing severity-based exit codes (10, 11, 12) requires a real or mocked
    # rayhunter instance returning alert data. These are covered by unit tests.
  end
end
