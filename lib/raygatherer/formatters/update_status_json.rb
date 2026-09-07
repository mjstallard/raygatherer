# frozen_string_literal: true

require "json"

module Raygatherer
  module Formatters
    class UpdateStatusJSON
      def format(status)
        ::JSON.generate(status)
      end
    end
  end
end
