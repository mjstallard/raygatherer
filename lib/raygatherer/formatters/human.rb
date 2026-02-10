# frozen_string_literal: true

require "colorize"

module Raygatherer
  module Formatters
    class Human
      def format(alerts)
        if alerts.empty?
          "✓ No alerts detected".green
        else
          alerts.map { |alert| format_alert(alert) }.join("\n\n")
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
