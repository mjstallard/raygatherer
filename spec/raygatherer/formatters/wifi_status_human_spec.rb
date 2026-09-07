# frozen_string_literal: true

RSpec.describe Raygatherer::Formatters::WifiStatusHuman do
  describe "#format" do
    let(:full_status) do
      {"state" => "connected", "ssid" => "attic-network", "ip" => "192.168.1.50", "txPackets" => 1024}
    end

    it "shows state" do
      output = described_class.new.format(full_status)

      expect(output).to include("State: connected")
    end

    it "shows ssid when present" do
      output = described_class.new.format(full_status)

      expect(output).to include("SSID: attic-network")
    end

    it "omits ssid when not present" do
      status = full_status.except("ssid")

      output = described_class.new.format(status)

      expect(output).not_to include("SSID")
    end

    it "shows ip when present" do
      output = described_class.new.format(full_status)

      expect(output).to include("IP: 192.168.1.50")
    end

    it "omits ip when not present" do
      status = full_status.except("ip")

      output = described_class.new.format(status)

      expect(output).not_to include("IP:")
    end

    it "shows txPackets when present" do
      output = described_class.new.format(full_status)

      expect(output).to include("TX packets: 1024")
    end

    it "omits txPackets when not present" do
      status = full_status.except("txPackets")

      output = described_class.new.format(status)

      expect(output).not_to include("TX packets")
    end

    it "shows error when present" do
      status = full_status.merge("error" => "authentication failed")

      output = described_class.new.format(status)

      expect(output).to include("Error: authentication failed")
    end

    it "omits error when not present" do
      output = described_class.new.format(full_status)

      expect(output).not_to include("Error:")
    end
  end
end
