# frozen_string_literal: true

require "json"

module Raygatherer
  module Formatters
    class StatsJSON
      def format(stats)
        ::JSON.generate(stats)
      end
    end
  end
end
