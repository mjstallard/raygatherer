# frozen_string_literal: true

require "colorize"

module Raygatherer
  module Formatters
    class Human
      def format(alert_data)
        if alert_data.nil?
          "✓ No alerts detected".green
        else
          format_alert(alert_data)
        end
      end

      private

      def format_alert(alert_data)
        severity = alert_data[:severity]
        message = alert_data[:message]

        icon = severity == "High" ? "🚨" : "⚠"
        color = severity == "High" ? :red : :yellow

        output = "#{icon} #{severity} severity alert detected\n"
        output += "Message: #{message}"
        output.colorize(color)
      end
    end
  end
end
