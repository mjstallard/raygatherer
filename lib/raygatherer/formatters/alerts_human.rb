# frozen_string_literal: true

module Raygatherer
  module Formatters
    class AlertsHuman
      def format(alerts)
        if alerts.empty?
          colorize("✓ No alerts detected", :green)
        else
          alerts.map { |alert| format_alert(alert) }.join("\n\n")
        end
      end

      private

      def format_alert(alert_data)
        severity = alert_data[:severity]
        message = alert_data[:message]
        analyzer = alert_data[:analyzer]
        timestamp = alert_data[:packet_timestamp]

        icon = (severity == "High") ? "🚨" : "⚠"
        color = (severity == "High") ? :red : :yellow

        output = "#{icon} #{severity} severity alert detected\n"
        output += "Analyzer: #{analyzer}\n" if analyzer
        output += "Time: #{timestamp}\n" if timestamp
        output += "Message: #{message}"
        colorize(output, color)
      end

      def colorize(text, color)
        codes = {red: "31", yellow: "33", green: "32"}
        "\e[0;#{codes[color]};49m#{text}\e[0m"
      end
    end
  end
end
