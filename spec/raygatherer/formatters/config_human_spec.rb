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
        "auto_check_updates" => true,
        "clock_sync_mode" => 2,
        "gps_mode" => 0,
        "gps_fixed_latitude" => nil,
        "gps_fixed_longitude" => nil,
        "wifi_enabled" => false,
        "wifi_ssid" => nil,
        "wifi_security" => nil,
        "dns_servers" => nil,
        "webdav" => {"url" => ""},
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

    it "shows auto check updates" do
      config = full_config.merge("auto_check_updates" => true)

      output = described_class.new.format(config)

      expect(output).to include("Auto check updates: true")
    end

    it "omits auto check updates when not present" do
      config = full_config.except("auto_check_updates")

      output = described_class.new.format(config)

      expect(output).not_to include("Auto check updates")
    end

    it "shows clock sync mode" do
      config = full_config.merge("clock_sync_mode" => 2)

      output = described_class.new.format(config)

      expect(output).to include("Clock sync mode: 2")
    end

    it "omits clock sync mode when not present" do
      config = full_config.except("clock_sync_mode")

      output = described_class.new.format(config)

      expect(output).not_to include("Clock sync mode")
    end

    it "shows GPS mode" do
      config = full_config.merge("gps_mode" => 2)

      output = described_class.new.format(config)

      expect(output).to include("GPS mode: 2")
    end

    it "omits GPS mode when not present" do
      config = full_config.except("gps_mode")

      output = described_class.new.format(config)

      expect(output).not_to include("GPS mode")
    end

    it "shows GPS fixed latitude and longitude when set" do
      config = full_config.merge("gps_fixed_latitude" => 51.5, "gps_fixed_longitude" => -0.1)

      output = described_class.new.format(config)

      expect(output).to include("GPS fixed latitude: 51.5")
      expect(output).to include("GPS fixed longitude: -0.1")
    end

    it "omits GPS fixed latitude and longitude when nil" do
      config = full_config.merge("gps_fixed_latitude" => nil, "gps_fixed_longitude" => nil)

      output = described_class.new.format(config)

      expect(output).not_to include("GPS fixed latitude")
      expect(output).not_to include("GPS fixed longitude")
    end

    it "shows wifi enabled" do
      config = full_config.merge("wifi_enabled" => true)

      output = described_class.new.format(config)

      expect(output).to include("WiFi enabled: true")
    end

    it "omits wifi enabled when not present" do
      config = full_config.except("wifi_enabled")

      output = described_class.new.format(config)

      expect(output).not_to include("WiFi enabled")
    end

    it "shows wifi ssid when set" do
      config = full_config.merge("wifi_ssid" => "attic-network")

      output = described_class.new.format(config)

      expect(output).to include("WiFi SSID: attic-network")
    end

    it "omits wifi ssid when nil" do
      config = full_config.merge("wifi_ssid" => nil)

      output = described_class.new.format(config)

      expect(output).not_to include("WiFi SSID")
    end

    it "shows wifi security when set" do
      config = full_config.merge("wifi_security" => "wpa_psk")

      output = described_class.new.format(config)

      expect(output).to include("WiFi security: wpa_psk")
    end

    it "omits wifi security when nil" do
      config = full_config.merge("wifi_security" => nil)

      output = described_class.new.format(config)

      expect(output).not_to include("WiFi security")
    end

    it "shows DNS servers when set" do
      config = full_config.merge("dns_servers" => ["1.1.1.1", "8.8.8.8"])

      output = described_class.new.format(config)

      expect(output).to include("DNS servers: 1.1.1.1, 8.8.8.8")
    end

    it "omits DNS servers when nil" do
      config = full_config.merge("dns_servers" => nil)

      output = described_class.new.format(config)

      expect(output).not_to include("DNS servers")
    end

    it "omits DNS servers when empty" do
      config = full_config.merge("dns_servers" => [])

      output = described_class.new.format(config)

      expect(output).not_to include("DNS servers")
    end

    it "never displays wifi_password even if present" do
      config = full_config.merge("wifi_password" => "hunter2")

      output = described_class.new.format(config)

      expect(output).not_to include("hunter2")
    end

    it "shows webdav section when url is set" do
      config = full_config.merge("webdav" => {
        "url" => "https://example.com/remote.php/dav",
        "username" => "mike",
        "upload_timeout_secs" => 300,
        "poll_interval_secs" => 3600,
        "min_age_secs" => 86400,
        "delete_on_upload" => false
      })

      output = described_class.new.format(config)

      expect(output).to include("WebDAV:")
      expect(output).to include("  URL: https://example.com/remote.php/dav")
      expect(output).to include("  Username: mike")
      expect(output).to include("  Upload timeout: 300s")
      expect(output).to include("  Poll interval: 3600s")
      expect(output).to include("  Min age: 86400s")
      expect(output).to include("  Delete on upload: false")
    end

    it "omits webdav section when url is empty" do
      config = full_config.merge("webdav" => {"url" => ""})

      output = described_class.new.format(config)

      expect(output).not_to include("WebDAV:")
    end

    it "omits webdav section when not present" do
      output = described_class.new.format(full_config)

      expect(output).not_to include("WebDAV:")
    end

    it "never displays webdav password even if present" do
      config = full_config.merge("webdav" => {"url" => "https://example.com", "password" => "hunter2"})

      output = described_class.new.format(config)

      expect(output).not_to include("hunter2")
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
