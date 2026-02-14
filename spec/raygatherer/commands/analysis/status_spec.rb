# frozen_string_literal: true

RSpec.describe Raygatherer::Commands::Analysis::Status do
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
          expect(stdout.string).to include("analysis status")
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

    describe "fetching and displaying analysis status" do
      let(:status) do
        {
          "queued" => ["rec1"],
          "running" => "rec2",
          "finished" => ["rec3", "rec4"]
        }
      end

      it "outputs human format by default" do
        allow(api_client).to receive(:fetch_analysis_status).and_return(status)

        exit_code = described_class.run([], stdout: stdout, stderr: stderr, api_client: api_client)

        expect(stdout.string).to include("Running: rec2")
        expect(stdout.string).to include("Queued (1):")
        expect(stdout.string).to include("Finished (2):")
        expect(exit_code).to eq(0)
      end

      it "outputs JSON when json: true" do
        allow(api_client).to receive(:fetch_analysis_status).and_return(status)

        exit_code = described_class.run([], stdout: stdout, stderr: stderr, api_client: api_client, json: true)

        parsed = ::JSON.parse(stdout.string.strip)
        expect(parsed["queued"]).to eq(["rec1"])
        expect(parsed["running"]).to eq("rec2")
        expect(exit_code).to eq(0)
      end
    end

    describe "error handling" do
      it "handles connection errors gracefully" do
        allow(api_client).to receive(:fetch_analysis_status).and_raise(
          Raygatherer::ApiClient::ConnectionError, "Connection failed"
        )

        exit_code = described_class.run([], stdout: stdout, stderr: stderr, api_client: api_client)

        expect(stderr.string).to include("Error: Connection failed")
        expect(exit_code).to eq(1)
      end

      it "handles API errors gracefully" do
        allow(api_client).to receive(:fetch_analysis_status).and_raise(
          Raygatherer::ApiClient::ApiError, "Server error"
        )

        exit_code = described_class.run([], stdout: stdout, stderr: stderr, api_client: api_client)

        expect(stderr.string).to include("Error: Server error")
        expect(exit_code).to eq(1)
      end
    end
  end
end
