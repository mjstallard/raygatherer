# frozen_string_literal: true

module Raygatherer
  module Formatters
    class WifiStatusHuman
      def format(status)
        lines = []

        lines << "State: #{status["state"]}"
        lines << "SSID: #{status["ssid"]}" if status["ssid"]
        lines << "IP: #{status["ip"]}" if status["ip"]
        lines << "TX packets: #{status["txPackets"]}" if status["txPackets"]
        lines << "Error: #{status["error"]}" if status["error"]

        lines.join("\n")
      end
    end
  end
end
