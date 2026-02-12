# frozen_string_literal: true

require "stringio"

RSpec.describe Raygatherer::Commands::Base do
  def build_command(action, stdout: StringIO.new, stderr: StringIO.new)
    klass = Class.new(described_class) do
      def initialize(argv, stdout:, stderr:, api_client: nil, action:)
        super(argv, stdout: stdout, stderr: stderr, api_client: api_client)
        @action = action
      end

      def run
        with_error_handling(extra_errors: [Raygatherer::ApiClient::ParseError]) do
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

  it "prints and returns 1 for extra errors" do
    command, _stdout, stderr = build_command(-> { raise Raygatherer::ApiClient::ParseError, "bad json" })

    expect(command.run).to eq(1)
    expect(stderr.string).to include("Error: bad json")
  end

  it "re-raises CLI::EarlyExit" do
    command, = build_command(-> { raise Raygatherer::CLI::EarlyExit, 0 })

    expect { command.run }.to raise_error(Raygatherer::CLI::EarlyExit)
  end

  it "prints global options with json flag" do
    command, _stdout, stderr = build_command(-> { 0 })
    output = StringIO.new

    command.send(:print_global_options, output, json: true)

    expect(output.string).to include("--json")
    expect(output.string).to include("--host")
    expect(stderr.string).to eq("")
  end
end
