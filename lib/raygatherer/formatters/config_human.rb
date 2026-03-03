# frozen_string_literal: true

module Raygatherer
  module Formatters
    class ConfigHuman
      def format(config)
        lines = []

        lines << "Port: #{config["port"]}"
        lines << "Readonly port: #{config["readonly_port"]}" if config.key?("readonly_port")
        lines << "QMDL store path: #{config["qmdl_store_path"]}"

        notification_url = config["ntfy_url"] || config["notification_url"]
        lines << "Notification URL: #{notification_url || "(not set)"}"

        if config.key?("min_space_to_start_recording_mb")
          lines << "Min space to start recording: #{config["min_space_to_start_recording_mb"]} MB"
        end
        if config.key?("min_space_to_continue_recording_mb")
          lines << "Min space to continue recording: #{config["min_space_to_continue_recording_mb"]} MB"
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
