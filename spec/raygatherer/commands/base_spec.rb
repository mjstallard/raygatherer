# frozen_string_literal: true

require "stringio"

RSpec.describe Raygatherer::Commands::Base do
  def build_command(action, stdout: StringIO.new, stderr: StringIO.new)
    klass = Class.new(described_class) do
      def initialize(argv, stdout:, stderr:, action:, api_client: nil)
        super(argv, stdout: stdout, stderr: stderr, api_client: api_client)
        @action = action
      end

      def run
        with_error_handling do
          @action.call
        end
      end
    end

    [klass.new([], stdout: stdout, stderr: stderr, action: action), stdout, stderr]
  end

  it "returns the block value on success" do
    command, = build_command(-> { 0 })

    expect(command.run).to eq(0)
  end

  it "prints and returns 1 for ApiError" do
    command, _stdout, stderr = build_command(-> { raise Raygatherer::ApiClient::ApiError, "nope" })

    expect(command.run).to eq(1)
    expect(stderr.string).to include("Error: nope")
  end

  it "prints and returns 1 for ParseError" do
    command, _stdout, stderr = build_command(-> { raise Raygatherer::ApiClient::ParseError, "bad json" })

    expect(command.run).to eq(1)
    expect(stderr.string).to include("Error: bad json")
  end

  it "re-raises CLI::EarlyExit" do
    command, = build_command(-> { raise Raygatherer::CLI::EarlyExit, 0 })

    expect { command.run }.to raise_error(Raygatherer::CLI::EarlyExit)
  end

  it "omits --json from global options by default" do
    command, _stdout, stderr = build_command(-> { 0 })
    output = StringIO.new

    command.send(:print_global_options, output)

    expect(output.string).not_to include("--json")
    expect(output.string).to include("--host")
    expect(stderr.string).to eq("")
  end

  it "includes --json in global options when the command supports it" do
    klass = Class.new(described_class) do
      def self.supports_json?
        true
      end

      def initialize(argv, stdout:, stderr:, action:, api_client: nil)
        super(argv, stdout: stdout, stderr: stderr, api_client: api_client)
        @action = action
      end
    end
    command = klass.new([], stdout: StringIO.new, stderr: StringIO.new, action: -> { 0 })
    output = StringIO.new

    command.send(:print_global_options, output)

    expect(output.string).to include("--json")
    expect(output.string).to include("--host")
  end

  describe "#warn_if_rayhunter_outdated" do
    it "warns on stderr when the connected rayhunter is older than tested" do
      command, _stdout, stderr = build_command(-> { 0 })

      command.send(:warn_if_rayhunter_outdated, "0.10.2")

      expect(stderr.string).to include("Warning:")
      expect(stderr.string).to include("0.10.2")
      expect(stderr.string).to include(Raygatherer::TESTED_RAYHUNTER_VERSION)
    end

    it "does not warn when the connected rayhunter matches the tested version" do
      command, _stdout, stderr = build_command(-> { 0 })

      command.send(:warn_if_rayhunter_outdated, Raygatherer::TESTED_RAYHUNTER_VERSION)

      expect(stderr.string).to eq("")
    end

    it "does not warn when the connected rayhunter is newer than tested" do
      command, _stdout, stderr = build_command(-> { 0 })

      command.send(:warn_if_rayhunter_outdated, "99.0.0")

      expect(stderr.string).to eq("")
    end

    it "does not warn and does not raise when the version string is unparseable" do
      command, _stdout, stderr = build_command(-> { 0 })

      expect { command.send(:warn_if_rayhunter_outdated, "not-a-version") }.not_to raise_error
      expect(stderr.string).to eq("")
    end
  end
end
