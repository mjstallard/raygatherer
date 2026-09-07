# frozen_string_literal: true

RSpec.describe Raygatherer::Commands::Gps::Show do
  describe ".run" do
    include_context "command context"
    let(:gps_data) { {"latitude" => 51.5, "longitude" => -0.1} }

    it_behaves_like "a command with help", "gps show"

    it "outputs human format by default" do
      allow(api_client).to receive(:fetch_gps).and_return(gps_data)

      exit_code = described_class.run([], stdout: stdout, stderr: stderr, api_client: api_client)

      expect(stdout.string).to include("Latitude:  51.5")
      expect(stdout.string).to include("Longitude: -0.1")
      expect(exit_code).to eq(0)
    end

    it "outputs JSON when json: true" do
      allow(api_client).to receive(:fetch_gps).and_return(gps_data)

      exit_code = described_class.run([], stdout: stdout, stderr: stderr, api_client: api_client, json: true)

      parsed = ::JSON.parse(stdout.string.strip)
      expect(parsed["latitude"]).to eq(51.5)
      expect(exit_code).to eq(0)
    end

    it "shows a friendly message and still exits 0 when no position is known" do
      allow(api_client).to receive(:fetch_gps).and_return(nil)

      exit_code = described_class.run([], stdout: stdout, stderr: stderr, api_client: api_client)

      expect(stdout.string).to include("No GPS position recorded yet")
      expect(exit_code).to eq(0)
    end

    it_behaves_like "command error handling", api_method: :fetch_gps
  end
end
