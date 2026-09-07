# frozen_string_literal: true

RSpec.describe Raygatherer::Formatters::WifiStatusJSON do
  describe "#format" do
    it "outputs valid JSON preserving all fields" do
      status = {"state" => "connected", "ssid" => "attic-network", "ip" => "192.168.1.50"}

      output = described_class.new.format(status)

      parsed = ::JSON.parse(output)
      expect(parsed["state"]).to eq("connected")
      expect(parsed["ssid"]).to eq("attic-network")
      expect(parsed["ip"]).to eq("192.168.1.50")
    end
  end
end
