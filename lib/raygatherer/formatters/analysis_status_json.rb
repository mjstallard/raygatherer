# frozen_string_literal: true

require "json"

module Raygatherer
  module Formatters
    class AnalysisStatusJSON
      def format(status)
        ::JSON.generate(status)
      end
    end
  end
end
