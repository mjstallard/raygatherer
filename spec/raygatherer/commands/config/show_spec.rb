# frozen_string_literal: true

RSpec.describe Raygatherer::Commands::Config::Show do
  describe ".run" do
    let(:stdout) { StringIO.new }
    let(:stderr) { StringIO.new }
    let(:api_client) { instance_double(Raygatherer::ApiClient) }

    let(:config_data) do
      {
        "qmdl_store_path" => "/data/rayhunter",
        "port" => 8080,
        "readonly_port" => 8081,
        "notification_url" => nil,
        "analyzers" => {
          "null_cipher" => true,
          "imsi_catcher" => true
        }
      }
    end

    describe "--help flag" do
      it "shows help with --help" do
        expect do
          described_class.run(["--help"], stdout: stdout, stderr: stderr)
        end.to raise_error(Raygatherer::CLI::EarlyExit) do |error|
          expect(error.exit_code).to eq(0)
          expect(stdout.string).to include("Usage:")
          expect(stdout.string).to include("config show")
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

    describe "fetching and displaying config" do
      it "outputs human format by default" do
        allow(api_client).to receive(:fetch_config).and_return(config_data)

        exit_code = described_class.run([], stdout: stdout, stderr: stderr, api_client: api_client)

        expect(stdout.string).to include("Port: 8080")
        expect(stdout.string).to include("Analyzers:")
        expect(exit_code).to eq(0)
      end

      it "outputs JSON when json: true" do
        allow(api_client).to receive(:fetch_config).and_return(config_data)

        exit_code = described_class.run([], stdout: stdout, stderr: stderr, api_client: api_client, json: true)

        parsed = ::JSON.parse(stdout.string.strip)
        expect(parsed["port"]).to eq(8080)
        expect(exit_code).to eq(0)
      end
    end

    describe "error handling" do
      it "handles connection errors gracefully" do
        allow(api_client).to receive(:fetch_config).and_raise(
          Raygatherer::ApiClient::ConnectionError, "Connection failed"
        )

        exit_code = described_class.run([], stdout: stdout, stderr: stderr, api_client: api_client)

        expect(stderr.string).to include("Error: Connection failed")
        expect(exit_code).to eq(1)
      end

      it "handles API errors gracefully" do
        allow(api_client).to receive(:fetch_config).and_raise(
          Raygatherer::ApiClient::ApiError, "Server error"
        )

        exit_code = described_class.run([], stdout: stdout, stderr: stderr, api_client: api_client)

        expect(stderr.string).to include("Error: Server error")
        expect(exit_code).to eq(1)
      end
    end
  end
end
