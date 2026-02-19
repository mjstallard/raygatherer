# frozen_string_literal: true

module Raygatherer
  module Formatters
    class TimeHuman
      def format(time)
        lines = []
        lines << "System time:   #{time["system_time"]}"
        lines << "Adjusted time: #{time["adjusted_time"]}"
        lines << "Offset:        #{time["offset_seconds"]}s"
        lines.join("\n")
      end
    end
  end
end
