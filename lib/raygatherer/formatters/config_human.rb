# frozen_string_literal: true

module Raygatherer
  module Formatters
    class ConfigHuman
      def format(config)
        lines = []

        lines << "Port: #{config["port"]}"
        lines << "Readonly port: #{config["readonly_port"]}"
        lines << "QMDL store path: #{config["qmdl_store_path"]}"

        notification_url = config["notification_url"]
        lines << "Notification URL: #{notification_url || "(not set)"}"

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
