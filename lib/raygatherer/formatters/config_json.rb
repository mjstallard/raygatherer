# frozen_string_literal: true

require "json"

module Raygatherer
  module Formatters
    class ConfigJSON
      def format(config)
        ::JSON.generate(config)
      end
    end
  end
end
