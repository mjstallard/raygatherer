# frozen_string_literal: true

require "json"
require "time"

module Raygatherer
  module Formatters
    class JSON
      def format(alert_data)
        output = {
          severity: alert_data&.dig(:severity),
          message: alert_data&.dig(:message),
          timestamp: Time.now.utc.iso8601
        }

        ::JSON.generate(output)
      end
    end
  end
end
