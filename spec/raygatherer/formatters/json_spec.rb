# frozen_string_literal: true

RSpec.describe Raygatherer::Formatters::JSON do
  describe "#format" do
    it "formats nil alert as JSON with null severity/message" do
      formatter = described_class.new
      output = formatter.format(nil)

      parsed = ::JSON.parse(output)
      expect(parsed["severity"]).to be_nil
      expect(parsed["message"]).to be_nil
      expect(parsed["timestamp"]).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/)
    end

    it "formats Low severity alert as JSON" do
      formatter = described_class.new
      alert_data = { severity: "Low", message: "Low severity issue detected" }
      output = formatter.format(alert_data)

      parsed = ::JSON.parse(output)
      expect(parsed["severity"]).to eq("Low")
      expect(parsed["message"]).to eq("Low severity issue detected")
      expect(parsed["timestamp"]).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/)
    end

    it "formats Medium severity alert as JSON" do
      formatter = described_class.new
      alert_data = { severity: "Medium", message: "Connection redirect detected" }
      output = formatter.format(alert_data)

      parsed = ::JSON.parse(output)
      expect(parsed["severity"]).to eq("Medium")
      expect(parsed["message"]).to eq("Connection redirect detected")
      expect(parsed["timestamp"]).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/)
    end

    it "formats High severity alert as JSON" do
      formatter = described_class.new
      alert_data = { severity: "High", message: "IMSI catcher detected" }
      output = formatter.format(alert_data)

      parsed = ::JSON.parse(output)
      expect(parsed["severity"]).to eq("High")
      expect(parsed["message"]).to eq("IMSI catcher detected")
      expect(parsed["timestamp"]).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/)
    end

    it "includes ISO 8601 timestamp in UTC" do
      formatter = described_class.new
      alert_data = { severity: "High", message: "Test" }
      output = formatter.format(alert_data)

      parsed = ::JSON.parse(output)
      # ISO 8601 format: 2024-02-08T15:30:45Z
      expect(parsed["timestamp"]).to match(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/)

      # Verify it's valid timestamp
      expect { Time.iso8601(parsed["timestamp"]) }.not_to raise_error
    end

    it "output is valid JSON (parseable)" do
      formatter = described_class.new
      alert_data = { severity: "High", message: "Test message" }
      output = formatter.format(alert_data)

      # Should not raise error
      expect { ::JSON.parse(output) }.not_to raise_error

      # Should be valid JSON with expected keys
      parsed = ::JSON.parse(output)
      expect(parsed.keys).to contain_exactly("severity", "message", "timestamp")
    end
  end
end
