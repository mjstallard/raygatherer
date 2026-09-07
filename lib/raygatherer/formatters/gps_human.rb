# frozen_string_literal: true

module Raygatherer
  module Formatters
    class GpsHuman
      def format(gps)
        return "No GPS position recorded yet (nothing has been submitted to /api/gps this session)." if gps.nil?

        "Latitude:  #{gps["latitude"]}\nLongitude: #{gps["longitude"]}"
      end
    end
  end
end
