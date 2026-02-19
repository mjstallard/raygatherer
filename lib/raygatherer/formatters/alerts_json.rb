# frozen_string_literal: true

require "json"

module Raygatherer
  module Formatters
    class AlertsJSON
      def format(alerts)
        output = alerts.map do |alert|
          {
            severity: alert[:severity],
            message: alert[:message],
            packet_timestamp: alert[:packet_timestamp],
            analyzer: alert[:analyzer]
          }
        end

        JSON.generate(output)
      end
    end
  end
end
