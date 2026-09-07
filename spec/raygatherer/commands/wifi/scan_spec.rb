# frozen_string_literal: true

RSpec.describe Raygatherer::Commands::Wifi::Scan do
  describe ".run" do
    include_context "command context"
    let(:networks_data) { [{"ssid" => "attic-network", "signal_dbm" => -45, "security" => "wpa_psk"}] }

    it_behaves_like "a command with help", "wifi scan"

    it "outputs human format by default" do
      allow(api_client).to receive(:scan_wifi).and_return(networks_data)

      exit_code = described_class.run([], stdout: stdout, stderr: stderr, api_client: api_client)

      expect(stdout.string).to include("Networks: 1")
      expect(stdout.string).to include("attic-network (-45 dBm, wpa_psk)")
      expect(exit_code).to eq(0)
    end

    it "outputs JSON when json: true" do
      allow(api_client).to receive(:scan_wifi).and_return(networks_data)

      exit_code = described_class.run([], stdout: stdout, stderr: stderr, api_client: api_client, json: true)

      parsed = ::JSON.parse(stdout.string.strip)
      expect(parsed.first["ssid"]).to eq("attic-network")
      expect(exit_code).to eq(0)
    end

    it "shows a friendly message when no networks are found" do
      allow(api_client).to receive(:scan_wifi).and_return([])

      exit_code = described_class.run([], stdout: stdout, stderr: stderr, api_client: api_client)

      expect(stdout.string).to include("No networks found")
      expect(exit_code).to eq(0)
    end

    it_behaves_like "command error handling", api_method: :scan_wifi
  end
end
