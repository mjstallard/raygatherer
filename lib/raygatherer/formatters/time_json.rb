# frozen_string_literal: true

require "json"

module Raygatherer
  module Formatters
    class TimeJSON
      def format(time)
        ::JSON.generate(time)
      end
    end
  end
end
