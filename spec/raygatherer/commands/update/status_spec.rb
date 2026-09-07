# frozen_string_literal: true

RSpec.describe Raygatherer::Commands::Update::Status do
  describe ".run" do
    include_context "command context"

    let(:up_to_date_status) do
      {
        "current_version" => "0.12.0",
        "update_available" => false,
        "latest_version" => "0.12.0",
        "last_checked" => "2026-09-01T12:00:00+00:00"
      }
    end

    let(:outdated_status) do
      {
        "current_version" => "0.12.0",
        "update_available" => true,
        "latest_version" => "0.13.0",
        "latest_release_url" => "https://github.com/EFForg/rayhunter/releases/tag/v0.13.0",
        "last_checked" => "2026-09-01T12:00:00+00:00"
      }
    end

    it_behaves_like "a command with help", "update status"

    it "outputs human format by default" do
      allow(api_client).to receive(:fetch_update_status).and_return(up_to_date_status)

      exit_code = described_class.run([], stdout: stdout, stderr: stderr, api_client: api_client)

      expect(stdout.string).to include("Current version: 0.12.0")
      expect(stdout.string).to include("Update available: no")
      expect(exit_code).to eq(0)
    end

    it "outputs JSON when json: true" do
      allow(api_client).to receive(:fetch_update_status).and_return(up_to_date_status)

      exit_code = described_class.run([], stdout: stdout, stderr: stderr, api_client: api_client, json: true)

      parsed = ::JSON.parse(stdout.string.strip)
      expect(parsed["current_version"]).to eq("0.12.0")
      expect(parsed["update_available"]).to be false
      expect(exit_code).to eq(0)
    end

    it "returns exit code 20 when an update is available" do
      allow(api_client).to receive(:fetch_update_status).and_return(outdated_status)

      exit_code = described_class.run([], stdout: stdout, stderr: stderr, api_client: api_client)

      expect(exit_code).to eq(20)
    end

    it "returns exit code 0 when up to date" do
      allow(api_client).to receive(:fetch_update_status).and_return(up_to_date_status)

      exit_code = described_class.run([], stdout: stdout, stderr: stderr, api_client: api_client)

      expect(exit_code).to eq(0)
    end

    it "does not warn on stderr when the connected rayhunter is up to date" do
      allow(api_client).to receive(:fetch_update_status).and_return(up_to_date_status)

      described_class.run([], stdout: stdout, stderr: stderr, api_client: api_client)

      expect(stderr.string).to eq("")
    end

    it "warns on stderr when the connected rayhunter is older than tested" do
      status = up_to_date_status.merge("current_version" => "0.9.0")
      allow(api_client).to receive(:fetch_update_status).and_return(status)

      described_class.run([], stdout: stdout, stderr: stderr, api_client: api_client)

      expect(stderr.string).to include("Warning:")
      expect(stderr.string).to include("0.9.0")
    end

    it_behaves_like "command error handling", api_method: :fetch_update_status
  end
end
