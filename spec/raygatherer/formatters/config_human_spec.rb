# frozen_string_literal: true

RSpec.describe Raygatherer::Formatters::ConfigHuman do
  describe "#format" do
    let(:full_config) do
      {
        "qmdl_store_path" => "/data/rayhunter",
        "port" => 8080,
        "device" => "Orbic",
        "debug_mode" => false,
        "ui_level" => 1,
        "colorblind_mode" => false,
        "key_input_mode" => 0,
        "ntfy_url" => "https://ntfy.sh/my-topic",
        "enabled_notifications" => ["Warning", "LowBattery"],
        "min_space_to_start_recording_mb" => 10,
        "min_space_to_continue_recording_mb" => 5,
        "analyzers" => {
          "null_cipher" => true,
          "imsi_catcher" => false
        }
      }
    end

    it "shows device" do
      output = described_class.new.format(full_config)

      expect(output).to include("Device: Orbic")
    end

    it "shows debug mode" do
      output = described_class.new.format(full_config)

      expect(output).to include("Debug mode: false")
    end

    it "shows UI level" do
      output = described_class.new.format(full_config)

      expect(output).to include("UI level: 1")
    end

    it "shows colorblind mode" do
      output = described_class.new.format(full_config)

      expect(output).to include("Colorblind mode: false")
    end

    it "shows key input mode" do
      output = described_class.new.format(full_config)

      expect(output).to include("Key input mode: 0")
    end

    it "shows enabled notifications" do
      output = described_class.new.format(full_config)

      expect(output).to include("Notifications enabled: Warning, LowBattery")
    end

    it "shows port" do
      output = described_class.new.format(full_config)

      expect(output).to include("Port: 8080")
    end

    it "shows QMDL store path" do
      output = described_class.new.format(full_config)

      expect(output).to include("QMDL store path: /data/rayhunter")
    end

    it "shows ntfy URL when set" do
      output = described_class.new.format(full_config)

      expect(output).to include("Notification URL: https://ntfy.sh/my-topic")
    end

    it "shows (not set) when ntfy URL is nil" do
      config = full_config.merge("ntfy_url" => nil)

      output = described_class.new.format(config)

      expect(output).to include("Notification URL: (not set)")
    end

    it "falls back to legacy notification_url field" do
      config = full_config.except("ntfy_url").merge("notification_url" => "https://example.com/old")

      output = described_class.new.format(config)

      expect(output).to include("Notification URL: https://example.com/old")
    end

    it "shows min space to start recording" do
      output = described_class.new.format(full_config)

      expect(output).to include("Min space to start recording: 10 MB")
    end

    it "shows min space to continue recording" do
      output = described_class.new.format(full_config)

      expect(output).to include("Min space to continue recording: 5 MB")
    end

    it "omits disk space fields when not present" do
      config = full_config.except("min_space_to_start_recording_mb", "min_space_to_continue_recording_mb")

      output = described_class.new.format(config)

      expect(output).not_to include("Min space")
    end

    it "shows analyzers section" do
      output = described_class.new.format(full_config)

      expect(output).to include("Analyzers:")
      expect(output).to include("  null_cipher: enabled")
      expect(output).to include("  imsi_catcher: disabled")
    end

    it "handles missing analyzers" do
      config = full_config.except("analyzers")

      output = described_class.new.format(config)

      expect(output).not_to include("Analyzers:")
    end
  end
end
