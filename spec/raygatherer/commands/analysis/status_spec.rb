# frozen_string_literal: true

RSpec.describe Raygatherer::Commands::Analysis::Status do
  describe ".run" do
    include_context "command context"

    it_behaves_like "a command with help", "analysis status"

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

    it_behaves_like "command error handling",
      api_method: :fetch_analysis_status, include_parse_error: false
  end
end
