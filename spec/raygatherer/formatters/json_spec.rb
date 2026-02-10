# frozen_string_literal: true

RSpec.describe Raygatherer::Formatters::JSON do
  describe "#format" do
    it "formats empty alerts as empty JSON array" do
      formatter = described_class.new
      output = formatter.format([])

      parsed = ::JSON.parse(output)
      expect(parsed).to eq([])
    end

    it "formats single alert as JSON array with one element" do
      formatter = described_class.new
      alerts = [{ severity: "Low", message: "Low severity issue detected", packet_timestamp: "2024-02-07T14:25:32Z" }]
      output = formatter.format(alerts)

      parsed = ::JSON.parse(output)
      expect(parsed).to be_an(Array)
      expect(parsed.length).to eq(1)
      expect(parsed[0]["severity"]).to eq("Low")
      expect(parsed[0]["message"]).to eq("Low severity issue detected")
      expect(parsed[0]["packet_timestamp"]).to eq("2024-02-07T14:25:32Z")
    end

    it "formats multiple alerts as JSON array" do
      formatter = described_class.new
      alerts = [
        { severity: "Low", message: "Low issue", packet_timestamp: "2024-02-07T14:25:32Z" },
        { severity: "High", message: "High issue", packet_timestamp: "2024-02-07T14:25:33Z" }
      ]
      output = formatter.format(alerts)

      parsed = ::JSON.parse(output)
      expect(parsed).to be_an(Array)
      expect(parsed.length).to eq(2)
      expect(parsed[0]["severity"]).to eq("Low")
      expect(parsed[1]["severity"]).to eq("High")
    end

    it "includes packet_timestamp from rayhunter data" do
      formatter = described_class.new
      alerts = [{ severity: "High", message: "Test", packet_timestamp: "2024-02-07T14:25:32Z" }]
      output = formatter.format(alerts)

      parsed = ::JSON.parse(output)
      expect(parsed[0]["packet_timestamp"]).to eq("2024-02-07T14:25:32Z")
    end

    it "output is valid JSON array (parseable)" do
      formatter = described_class.new
      alerts = [{ severity: "High", message: "Test message", packet_timestamp: "2024-02-07T14:25:32Z" }]
      output = formatter.format(alerts)

      expect { ::JSON.parse(output) }.not_to raise_error

      parsed = ::JSON.parse(output)
      expect(parsed).to be_an(Array)
      expect(parsed[0].keys).to contain_exactly("severity", "message", "packet_timestamp")
    end
  end
end
