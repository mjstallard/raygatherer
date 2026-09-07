# frozen_string_literal: true

RSpec.describe Raygatherer::Formatters::WifiScanJSON do
  describe "#format" do
    it "outputs valid JSON preserving all networks" do
      networks = [{"ssid" => "attic-network", "signal_dbm" => -45, "security" => "wpa_psk"}]

      output = described_class.new.format(networks)

      parsed = ::JSON.parse(output)
      expect(parsed.length).to eq(1)
      expect(parsed.first["ssid"]).to eq("attic-network")
    end

    it "outputs an empty JSON array when no networks are found" do
      output = described_class.new.format([])

      expect(::JSON.parse(output)).to eq([])
    end
  end
end
