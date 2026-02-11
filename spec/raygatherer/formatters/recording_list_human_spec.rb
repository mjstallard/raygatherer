# frozen_string_literal: true

RSpec.describe Raygatherer::Formatters::RecordingListHuman do
  subject { described_class.new }

  describe "#format" do
    it "shows 'No recordings found' when entries and current_entry are empty/nil" do
      manifest = { "entries" => [], "current_entry" => nil }
      result = subject.format(manifest)

      expect(result).to include("No recordings found")
    end

    it "shows recording count in header" do
      manifest = {
        "entries" => [
          { "name" => "1738950000", "start_time" => "2025-02-07T13:40:00+00:00",
            "last_message_time" => "2025-02-07T15:30:00+00:00", "qmdl_size_bytes" => 134_963_200 }
        ],
        "current_entry" => nil
      }
      result = subject.format(manifest)

      expect(result).to include("Recordings: 1")
    end

    it "shows active count when current_entry is present" do
      manifest = {
        "entries" => [
          { "name" => "1738950000", "start_time" => "2025-02-07T13:40:00+00:00",
            "last_message_time" => "2025-02-07T15:30:00+00:00", "qmdl_size_bytes" => 134_963_200 }
        ],
        "current_entry" => {
          "name" => "1738956789", "start_time" => "2025-02-07T15:33:09+00:00",
          "last_message_time" => "2025-02-07T16:00:00+00:00", "qmdl_size_bytes" => 47_513_600
        }
      }
      result = subject.format(manifest)

      expect(result).to include("Recordings: 2 (1 active)")
    end

    it "shows active indicator for current_entry" do
      manifest = {
        "entries" => [],
        "current_entry" => {
          "name" => "1738956789", "start_time" => "2025-02-07T15:33:09+00:00",
          "last_message_time" => "2025-02-07T16:00:00+00:00", "qmdl_size_bytes" => 47_513_600
        }
      }
      result = subject.format(manifest)

      expect(result).to include("recording")
      expect(result).to include("1738956789")
    end

    it "shows current_entry first, before other entries" do
      manifest = {
        "entries" => [
          { "name" => "1738950000", "start_time" => "2025-02-07T13:40:00+00:00",
            "last_message_time" => "2025-02-07T15:30:00+00:00", "qmdl_size_bytes" => 134_963_200 }
        ],
        "current_entry" => {
          "name" => "1738956789", "start_time" => "2025-02-07T15:33:09+00:00",
          "last_message_time" => "2025-02-07T16:00:00+00:00", "qmdl_size_bytes" => 47_513_600
        }
      }
      result = subject.format(manifest)

      active_index = result.index("1738956789")
      inactive_index = result.index("1738950000")
      expect(active_index).to be < inactive_index
    end

    it "shows start time for entries" do
      manifest = {
        "entries" => [
          { "name" => "1738950000", "start_time" => "2025-02-07T13:40:00+00:00",
            "last_message_time" => "2025-02-07T15:30:00+00:00", "qmdl_size_bytes" => 134_963_200 }
        ],
        "current_entry" => nil
      }
      result = subject.format(manifest)

      expect(result).to include("Started:")
      expect(result).to include("2025-02-07 13:40:00")
    end

    it "shows last message time for inactive entries" do
      manifest = {
        "entries" => [
          { "name" => "1738950000", "start_time" => "2025-02-07T13:40:00+00:00",
            "last_message_time" => "2025-02-07T15:30:00+00:00", "qmdl_size_bytes" => 134_963_200 }
        ],
        "current_entry" => nil
      }
      result = subject.format(manifest)

      expect(result).to include("Last message:")
      expect(result).to include("2025-02-07 15:30:00")
    end

    it "formats size in bytes" do
      manifest = {
        "entries" => [
          { "name" => "small", "start_time" => "2025-02-07T13:40:00+00:00",
            "last_message_time" => "2025-02-07T15:30:00+00:00", "qmdl_size_bytes" => 512 }
        ],
        "current_entry" => nil
      }
      result = subject.format(manifest)

      expect(result).to include("512 B")
    end

    it "formats size in KB" do
      manifest = {
        "entries" => [
          { "name" => "medium", "start_time" => "2025-02-07T13:40:00+00:00",
            "last_message_time" => "2025-02-07T15:30:00+00:00", "qmdl_size_bytes" => 2_048 }
        ],
        "current_entry" => nil
      }
      result = subject.format(manifest)

      expect(result).to include("2.0 KB")
    end

    it "formats size in MB" do
      manifest = {
        "entries" => [
          { "name" => "large", "start_time" => "2025-02-07T13:40:00+00:00",
            "last_message_time" => "2025-02-07T15:30:00+00:00", "qmdl_size_bytes" => 47_513_600 }
        ],
        "current_entry" => nil
      }
      result = subject.format(manifest)

      expect(result).to include("45.3 MB")
    end

    it "formats size in GB" do
      manifest = {
        "entries" => [
          { "name" => "huge", "start_time" => "2025-02-07T13:40:00+00:00",
            "last_message_time" => "2025-02-07T15:30:00+00:00", "qmdl_size_bytes" => 2_147_483_648 }
        ],
        "current_entry" => nil
      }
      result = subject.format(manifest)

      expect(result).to include("2.0 GB")
    end
  end
end
