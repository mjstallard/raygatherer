# frozen_string_literal: true

require "json"

module Raygatherer
  module Formatters
    class GpsJSON
      def format(gps)
        ::JSON.generate(gps)
      end
    end
  end
end
