# frozen_string_literal: true

RSpec.describe Raygatherer::Commands::Analysis::Run do
  describe ".run" do
    let(:stdout) { StringIO.new }
    let(:stderr) { StringIO.new }
    let(:api_client) { instance_double(Raygatherer::ApiClient) }

    let(:status_response) do
      {
        "queued" => ["rec1"],
        "running" => nil,
        "finished" => []
      }
    end

    it_behaves_like "a command with help", "analysis run"

    describe "running analysis" do
      it "queues a named recording for analysis" do
        allow(api_client).to receive(:start_analysis).with("my_recording").and_return(status_response)

        exit_code = described_class.run(
          ["my_recording"],
          stdout: stdout, stderr: stderr, api_client: api_client
        )

        expect(stdout.string).to include("Queued (1):")
        expect(exit_code).to eq(0)
      end

      it "queues all recordings with --all" do
        allow(api_client).to receive(:start_analysis).with("").and_return(status_response)

        exit_code = described_class.run(
          ["--all"],
          stdout: stdout, stderr: stderr, api_client: api_client
        )

        expect(stdout.string).to include("Queued (1):")
        expect(exit_code).to eq(0)
      end

      it "outputs JSON when json: true" do
        allow(api_client).to receive(:start_analysis).with("my_recording").and_return(status_response)

        exit_code = described_class.run(
          ["my_recording"],
          stdout: stdout, stderr: stderr, api_client: api_client, json: true
        )

        parsed = ::JSON.parse(stdout.string.strip)
        expect(parsed["queued"]).to eq(["rec1"])
        expect(exit_code).to eq(0)
      end

      it "requires a name or --all" do
        exit_code = described_class.run(
          [],
          stdout: stdout, stderr: stderr, api_client: api_client
        )

        expect(stderr.string).to include("recording name or --all is required")
        expect(exit_code).to eq(1)
      end

      it "rejects both name and --all" do
        exit_code = described_class.run(
          ["my_recording", "--all"],
          stdout: stdout, stderr: stderr, api_client: api_client
        )

        expect(stderr.string).to include("cannot use --all with a recording name")
        expect(exit_code).to eq(1)
      end
    end

    it_behaves_like "command error handling",
      api_method: :start_analysis, run_args: ["my_recording"], include_parse_error: false
  end
end
