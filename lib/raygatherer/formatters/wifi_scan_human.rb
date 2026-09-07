# frozen_string_literal: true

module Raygatherer
  module Formatters
    class WifiScanHuman
      def format(networks)
        return "No networks found" if networks.empty?

        lines = ["Networks: #{networks.length}", ""]
        networks.each do |network|
          lines << "#{network["ssid"]} (#{network["signal_dbm"]} dBm, #{network["security"]})"
        end
        lines.join("\n")
      end
    end
  end
end
