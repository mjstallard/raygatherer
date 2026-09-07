# frozen_string_literal: true

require "json"

module Raygatherer
  module Formatters
    class AlertsJSON
      def format(alerts)
        JSON.generate(alerts)
      end
    end
  end
end
