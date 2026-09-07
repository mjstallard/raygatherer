# frozen_string_literal: true

require "json"

module Raygatherer
  module Formatters
    class AnalysisReportJSON
      def format(data)
        ::JSON.generate(data)
      end
    end
  end
end
