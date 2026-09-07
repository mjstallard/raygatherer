# frozen_string_literal: true

RSpec.describe Raygatherer::Formatters::UpdateStatusJSON do
  describe "#format" do
    it "outputs valid JSON" do
      status = {"current_version" => "0.12.0", "update_available" => false}

      output = described_class.new.format(status)

      expect { ::JSON.parse(output) }.not_to raise_error
    end

    it "preserves all fields" do
      status = {
        "current_version" => "0.12.0",
        "update_available" => true,
        "latest_version" => "0.13.0",
        "latest_release_url" => "https://github.com/EFForg/rayhunter/releases/tag/v0.13.0",
        "last_checked" => "2026-09-01T12:00:00+00:00"
      }

      output = described_class.new.format(status)

      parsed = ::JSON.parse(output)
      expect(parsed["current_version"]).to eq("0.12.0")
      expect(parsed["update_available"]).to be true
      expect(parsed["latest_version"]).to eq("0.13.0")
      expect(parsed["latest_release_url"]).to eq("https://github.com/EFForg/rayhunter/releases/tag/v0.13.0")
      expect(parsed["last_checked"]).to eq("2026-09-01T12:00:00+00:00")
    end
  end
end
