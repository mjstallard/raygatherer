# frozen_string_literal: true

require "json"

module Raygatherer
  module Formatters
    class AnalysisReportJSON
      def format(data)
        ::JSON.generate({"metadata" => data[:metadata], "rows" => data[:rows]})
      end
    end
  end
end
