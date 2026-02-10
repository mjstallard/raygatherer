# frozen_string_literal: true

require "json"
require "time"

module Raygatherer
  module Formatters
    class JSON
      def format(alerts)
        alert = alerts.first
        output = {
          severity: alert&.dig(:severity),
          message: alert&.dig(:message),
          timestamp: Time.now.utc.iso8601
        }

        ::JSON.generate(output)
      end
    end
  end
end
