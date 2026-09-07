# frozen_string_literal: true

RSpec.describe Raygatherer::Commands::Wifi::Show do
  describe ".run" do
    include_context "command context"
    let(:status_data) { {"state" => "connected", "ssid" => "attic-network", "ip" => "192.168.1.50"} }

    it_behaves_like "a command with help", "wifi show"

    it "outputs human format by default" do
      allow(api_client).to receive(:fetch_wifi_status).and_return(status_data)

      exit_code = described_class.run([], stdout: stdout, stderr: stderr, api_client: api_client)

      expect(stdout.string).to include("State: connected")
      expect(stdout.string).to include("SSID: attic-network")
      expect(exit_code).to eq(0)
    end

    it "outputs JSON when json: true" do
      allow(api_client).to receive(:fetch_wifi_status).and_return(status_data)

      exit_code = described_class.run([], stdout: stdout, stderr: stderr, api_client: api_client, json: true)

      parsed = ::JSON.parse(stdout.string.strip)
      expect(parsed["state"]).to eq("connected")
      expect(exit_code).to eq(0)
    end

    it_behaves_like "command error handling", api_method: :fetch_wifi_status
  end
end
