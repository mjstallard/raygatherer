# frozen_string_literal: true

RSpec.describe Raygatherer::Formatters::StatsJSON do
  describe "#format" do
    it "outputs valid JSON" do
      stats = {"disk_stats" => {}, "memory_stats" => {}}

      formatter = described_class.new
      output = formatter.format(stats)

      expect { ::JSON.parse(output) }.not_to raise_error
    end

    it "preserves all fields" do
      stats = {
        "disk_stats" => {"partition" => "/dev/sda1", "total_size" => "128G", "used_size" => "64G",
                         "available_size" => "64G", "used_percent" => "50%", "mounted_on" => "/data"},
        "memory_stats" => {"total" => "28.3M", "used" => "15.1M", "free" => "13.2M"},
        "runtime_metadata" => {"rayhunter_version" => "1.2.3", "system_os" => "Linux 3.18.48", "arch" => "armv7l"},
        "battery_status" => {"level" => 85, "is_plugged_in" => true}
      }

      formatter = described_class.new
      output = formatter.format(stats)

      parsed = ::JSON.parse(output)
      expect(parsed["disk_stats"]["total_size"]).to eq("128G")
      expect(parsed["memory_stats"]["free"]).to eq("13.2M")
      expect(parsed["runtime_metadata"]["rayhunter_version"]).to eq("1.2.3")
      expect(parsed["battery_status"]["level"]).to eq(85)
    end
  end
end
