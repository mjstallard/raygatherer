# frozen_string_literal: true

RSpec.describe Raygatherer::Formatters::WifiScanHuman do
  describe "#format" do
    it "shows a count and one line per network" do
      networks = [
        {"ssid" => "attic-network", "signal_dbm" => -45, "security" => "wpa_psk"},
        {"ssid" => "neighbor", "signal_dbm" => -80, "security" => "sae"}
      ]

      output = described_class.new.format(networks)

      expect(output).to include("Networks: 2")
      expect(output).to include("attic-network (-45 dBm, wpa_psk)")
      expect(output).to include("neighbor (-80 dBm, sae)")
    end

    it "shows a friendly message when no networks are found" do
      output = described_class.new.format([])

      expect(output).to eq("No networks found")
    end
  end
end
