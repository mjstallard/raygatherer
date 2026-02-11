# frozen_string_literal: true

require "json"

module Raygatherer
  module Formatters
    class RecordingListJSON
      def format(manifest)
        ::JSON.generate(manifest)
      end
    end
  end
end
