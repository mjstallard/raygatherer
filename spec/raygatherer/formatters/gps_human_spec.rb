# frozen_string_literal: true

RSpec.describe Raygatherer::Formatters::GpsHuman do
  describe "#format" do
    it "shows latitude and longitude" do
      gps = {"latitude" => 51.5, "longitude" => -0.1}

      output = described_class.new.format(gps)

      expect(output).to include("Latitude:  51.5")
      expect(output).to include("Longitude: -0.1")
    end

    it "shows a friendly message when no position has been recorded" do
      output = described_class.new.format(nil)

      expect(output).to include("No GPS position recorded yet")
    end
  end
end
