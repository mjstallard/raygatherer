# frozen_string_literal: true

RSpec.describe Raygatherer::Commands::Config::Set do
  describe ".run" do
    let(:stdout) { StringIO.new }
    let(:stderr) { StringIO.new }
    let(:api_client) { instance_double(Raygatherer::ApiClient) }

    describe "--help flag" do
      it "shows help with --help" do
        expect do
          described_class.run(["--help"], stdout: stdout, stderr: stderr)
        end.to raise_error(Raygatherer::CLI::EarlyExit) do |error|
          expect(error.exit_code).to eq(0)
          expect(stdout.string).to include("Usage:")
          expect(stdout.string).to include("config set")
        end
      end

      it "shows help with -h" do
        expect do
          described_class.run(["-h"], stdout: stdout, stderr: stderr)
        end.to raise_error(Raygatherer::CLI::EarlyExit) do |error|
          expect(error.exit_code).to eq(0)
        end
      end
    end

    describe "setting config" do
      it "reads JSON from stdin and sends to API" do
        stdin = StringIO.new('{"port":9090}')
        allow(api_client).to receive(:set_config)

        exit_code = described_class.run(
          [],
          stdout: stdout, stderr: stderr, api_client: api_client, stdin: stdin
        )

        expect(api_client).to have_received(:set_config).with('{"port":9090}')
        expect(stdout.string).to include("Configuration updated")
        expect(exit_code).to eq(0)
      end

      it "reports error when stdin is empty" do
        stdin = StringIO.new("")

        exit_code = described_class.run(
          [],
          stdout: stdout, stderr: stderr, api_client: api_client, stdin: stdin
        )

        expect(stderr.string).to include("no JSON input received")
        expect(exit_code).to eq(1)
      end

      it "validates JSON before sending" do
        stdin = StringIO.new("not valid json")

        exit_code = described_class.run(
          [],
          stdout: stdout, stderr: stderr, api_client: api_client, stdin: stdin
        )

        expect(stderr.string).to include("invalid JSON")
        expect(exit_code).to eq(1)
      end
    end

    describe "error handling" do
      it "handles connection errors gracefully" do
        stdin = StringIO.new('{"port":9090}')
        allow(api_client).to receive(:set_config).and_raise(
          Raygatherer::ApiClient::ConnectionError, "Connection failed"
        )

        exit_code = described_class.run(
          [],
          stdout: stdout, stderr: stderr, api_client: api_client, stdin: stdin
        )

        expect(stderr.string).to include("Error: Connection failed")
        expect(exit_code).to eq(1)
      end

      it "handles API errors gracefully" do
        stdin = StringIO.new('{"port":9090}')
        allow(api_client).to receive(:set_config).and_raise(
          Raygatherer::ApiClient::ApiError, "Server returned 400: Invalid config"
        )

        exit_code = described_class.run(
          [],
          stdout: stdout, stderr: stderr, api_client: api_client, stdin: stdin
        )

        expect(stderr.string).to include("Error: Server returned 400")
        expect(exit_code).to eq(1)
      end
    end
  end
end
