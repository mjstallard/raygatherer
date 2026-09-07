# frozen_string_literal: true

module Raygatherer
  module Formatters
    class ConfigHuman
      def format(config)
        lines = []

        lines << "Port: #{config["port"]}"
        lines << "QMDL store path: #{config["qmdl_store_path"]}"
        lines << "Device: #{config["device"]}" if config.key?("device")
        lines << "Debug mode: #{config["debug_mode"]}" if config.key?("debug_mode")
        lines << "UI level: #{config["ui_level"]}" if config.key?("ui_level")
        lines << "Colorblind mode: #{config["colorblind_mode"]}" if config.key?("colorblind_mode")
        lines << "Key input mode: #{config["key_input_mode"]}" if config.key?("key_input_mode")

        notification_url = config["ntfy_url"] || config["notification_url"]
        lines << "Notification URL: #{notification_url || "(not set)"}"

        if config.key?("enabled_notifications")
          lines << "Notifications enabled: #{config["enabled_notifications"].join(", ")}"
        end

        if config.key?("min_space_to_start_recording_mb")
          lines << "Min space to start recording: #{config["min_space_to_start_recording_mb"]} MB"
        end
        if config.key?("min_space_to_continue_recording_mb")
          lines << "Min space to continue recording: #{config["min_space_to_continue_recording_mb"]} MB"
        end

        lines << "Auto check updates: #{config["auto_check_updates"]}" if config.key?("auto_check_updates")
        lines << "Clock sync mode: #{config["clock_sync_mode"]}" if config.key?("clock_sync_mode")
        lines << "GPS mode: #{config["gps_mode"]}" if config.key?("gps_mode")
        lines << "GPS fixed latitude: #{config["gps_fixed_latitude"]}" if config["gps_fixed_latitude"]
        lines << "GPS fixed longitude: #{config["gps_fixed_longitude"]}" if config["gps_fixed_longitude"]
        lines << "WiFi enabled: #{config["wifi_enabled"]}" if config.key?("wifi_enabled")
        lines << "WiFi SSID: #{config["wifi_ssid"]}" if config["wifi_ssid"]
        lines << "WiFi security: #{config["wifi_security"]}" if config["wifi_security"]
        lines << "DNS servers: #{config["dns_servers"].join(", ")}" if config["dns_servers"]&.any?

        webdav = config["webdav"]
        if webdav && !webdav["url"].to_s.empty?
          lines << ""
          lines << "WebDAV:"
          lines << "  URL: #{webdav["url"]}"
          lines << "  Username: #{webdav["username"]}" if webdav["username"]
          lines << "  Upload timeout: #{webdav["upload_timeout_secs"]}s" if webdav.key?("upload_timeout_secs")
          lines << "  Poll interval: #{webdav["poll_interval_secs"]}s" if webdav.key?("poll_interval_secs")
          lines << "  Min age: #{webdav["min_age_secs"]}s" if webdav.key?("min_age_secs")
          lines << "  Delete on upload: #{webdav["delete_on_upload"]}" if webdav.key?("delete_on_upload")
        end

        analyzers = config["analyzers"]
        if analyzers
          lines << ""
          lines << "Analyzers:"
          analyzers.each do |name, enabled|
            lines << "  #{name}: #{enabled ? "enabled" : "disabled"}"
          end
        end

        lines.join("\n")
      end
    end
  end
end
