# frozen_string_literal: true

require "json"

module Raygatherer
  module Formatters
    class WifiScanJSON
      def format(networks)
        ::JSON.generate(networks)
      end
    end
  end
end
