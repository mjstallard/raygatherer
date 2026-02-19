# frozen_string_literal: true

RSpec.describe Raygatherer::Formatters::AlertsHuman do
  describe "#format" do
    it "shows green checkmark when no alerts" do
      result = subject.format([])

      expect(result).to include("✓")
      expect(result).to include("No alerts detected")
      # Green color code
      expect(result).to include("\e[0;32")
    end

    it "shows yellow warning for Low severity with analyzer and timestamp" do
      alerts = [{severity: "Low", message: "Test low alert", analyzer: "Analyzer A", packet_timestamp: "2024-02-07T14:25:32Z"}]
      result = subject.format(alerts)

      expect(result).to include("⚠")
      expect(result).to include("Low severity alert detected")
      expect(result).to include("Test low alert")
      expect(result).to include("Analyzer A")
      expect(result).to include("2024-02-07T14:25:32Z")
      # Yellow color code
      expect(result).to include("\e[0;33")
    end

    it "shows yellow warning for Medium severity" do
      alerts = [{severity: "Medium", message: "Connection redirect to 2G detected", analyzer: "Analyzer B", packet_timestamp: "2024-02-07T14:25:33Z"}]
      result = subject.format(alerts)

      expect(result).to include("⚠")
      expect(result).to include("Medium severity alert detected")
      expect(result).to include("Connection redirect to 2G detected")
      # Yellow color code
      expect(result).to include("\e[0;33")
    end

    it "shows red alert for High severity" do
      alerts = [{severity: "High", message: "Critical IMSI catcher detected", analyzer: "Analyzer A", packet_timestamp: "2024-02-07T14:25:32Z"}]
      result = subject.format(alerts)

      expect(result).to include("🚨")
      expect(result).to include("High severity alert detected")
      expect(result).to include("Critical IMSI catcher detected")
      # Red color code
      expect(result).to include("\e[0;31")
    end

    it "shows multiple alerts separated by blank lines" do
      alerts = [
        {severity: "Low", message: "Low issue", analyzer: "Analyzer A", packet_timestamp: "2024-02-07T14:25:32Z"},
        {severity: "High", message: "High issue", analyzer: "Analyzer B", packet_timestamp: "2024-02-07T14:25:33Z"}
      ]
      result = subject.format(alerts)

      expect(result).to include("Low issue")
      expect(result).to include("High issue")
      expect(result).to include("Analyzer A")
      expect(result).to include("Analyzer B")
    end
  end
end
