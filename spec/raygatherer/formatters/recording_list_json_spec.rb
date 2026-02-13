# frozen_string_literal: true

RSpec.describe Raygatherer::Formatters::RecordingListJSON do
  describe "#format" do
    it "outputs the manifest structure as JSON" do
      manifest = {
        "entries" => [
          {
            "name" => "1738950000",
            "start_time" => "2025-02-07T13:40:00+00:00",
            "last_message_time" => "2025-02-07T15:30:00+00:00",
            "qmdl_size_bytes" => 134_963_200
          }
        ],
        "current_entry" => nil
      }

      formatter = described_class.new
      output = formatter.format(manifest)

      parsed = ::JSON.parse(output)
      expect(parsed["entries"].length).to eq(1)
      expect(parsed["entries"].first["name"]).to eq("1738950000")
      expect(parsed["current_entry"]).to be_nil
    end

    it "includes current_entry when present" do
      manifest = {
        "entries" => [],
        "current_entry" => {
          "name" => "1738956789",
          "start_time" => "2025-02-07T15:33:09+00:00",
          "qmdl_size_bytes" => 47_513_600
        }
      }

      formatter = described_class.new
      output = formatter.format(manifest)

      parsed = ::JSON.parse(output)
      expect(parsed["current_entry"]["name"]).to eq("1738956789")
      expect(parsed["entries"]).to eq([])
    end

    it "outputs valid JSON" do
      manifest = {"entries" => [], "current_entry" => nil}

      formatter = described_class.new
      output = formatter.format(manifest)

      expect { ::JSON.parse(output) }.not_to raise_error
    end
  end
end
