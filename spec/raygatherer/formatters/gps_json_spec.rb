# frozen_string_literal: true

RSpec.describe Raygatherer::Formatters::GpsJSON do
  describe "#format" do
    it "outputs valid JSON preserving latitude and longitude" do
      gps = {"latitude" => 51.5, "longitude" => -0.1}

      output = described_class.new.format(gps)

      parsed = ::JSON.parse(output)
      expect(parsed["latitude"]).to eq(51.5)
      expect(parsed["longitude"]).to eq(-0.1)
    end

    it "outputs null when no position has been recorded" do
      output = described_class.new.format(nil)

      expect(output).to eq("null")
    end
  end
end
