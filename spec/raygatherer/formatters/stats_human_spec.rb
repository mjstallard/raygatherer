# frozen_string_literal: true

RSpec.describe Raygatherer::Formatters::StatsHuman do
  describe "#format" do
    let(:full_stats) do
      {
        "disk_stats" => {"partition" => "/dev/sda1", "total_size" => "128G", "used_size" => "64G",
                         "available_size" => "64G", "used_percent" => "50%", "mounted_on" => "/data"},
        "memory_stats" => {"total" => "28.3M", "used" => "15.1M", "free" => "13.2M"},
        "runtime_metadata" => {"rayhunter_version" => "1.2.3", "system_os" => "Linux 3.18.48", "arch" => "armv7l"},
        "battery_status" => {"level" => 85, "is_plugged_in" => true}
      }
    end

    it "shows runtime metadata header" do
      output = described_class.new.format(full_stats)

      expect(output).to include("Rayhunter v1.2.3 | Linux 3.18.48 | armv7l")
    end

    it "shows disk usage" do
      output = described_class.new.format(full_stats)

      expect(output).to include("Disk: 64G / 128G (50%) on /data")
    end

    it "shows memory usage" do
      output = described_class.new.format(full_stats)

      expect(output).to include("Memory: 15.1M / 28.3M (13.2M free)")
    end

    it "shows battery when plugged in" do
      output = described_class.new.format(full_stats)

      expect(output).to include("Battery: 85% (plugged in)")
    end

    it "shows battery when on battery" do
      stats = full_stats.merge("battery_status" => {"level" => 42, "is_plugged_in" => false})

      output = described_class.new.format(stats)

      expect(output).to include("Battery: 42% (on battery)")
    end

    it "omits battery line when battery_status is absent" do
      stats = full_stats.reject { |k, _| k == "battery_status" }

      output = described_class.new.format(stats)

      expect(output).not_to include("Battery")
    end
  end
end
