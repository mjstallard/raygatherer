# frozen_string_literal: true

RSpec.describe Raygatherer::Formatters::Human do
  describe "#format" do
    it "shows green checkmark when no alerts" do
      result = subject.format(nil)

      expect(result).to include("✓")
      expect(result).to include("No alerts detected")
      # Green color code
      expect(result).to include("\e[0;32")
    end

    it "shows yellow warning for Low severity" do
      alert = { severity: "Low", message: "Test low alert" }
      result = subject.format(alert)

      expect(result).to include("⚠")
      expect(result).to include("Low severity alert detected")
      expect(result).to include("Test low alert")
      # Yellow color code
      expect(result).to include("\e[0;33")
    end

    it "shows yellow warning for Medium severity" do
      alert = { severity: "Medium", message: "Connection redirect to 2G detected" }
      result = subject.format(alert)

      expect(result).to include("⚠")
      expect(result).to include("Medium severity alert detected")
      expect(result).to include("Connection redirect to 2G detected")
      # Yellow color code
      expect(result).to include("\e[0;33")
    end

    it "shows red alert for High severity" do
      alert = { severity: "High", message: "Critical IMSI catcher detected" }
      result = subject.format(alert)

      expect(result).to include("🚨")
      expect(result).to include("High severity alert detected")
      expect(result).to include("Critical IMSI catcher detected")
      # Red color code
      expect(result).to include("\e[0;31")
    end

    it "handles alerts with symbols for keys" do
      alert = { severity: "Medium", message: "Test message" }
      result = subject.format(alert)

      expect(result).to include("Medium severity alert detected")
      expect(result).to include("Test message")
    end
  end
end
