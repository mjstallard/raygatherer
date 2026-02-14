# frozen_string_literal: true

module Raygatherer
  module Formatters
    class AnalysisStatusHuman
      def format(status)
        lines = []

        running = status["running"]
        lines << if running
          "Running: #{running}"
        else
          "Running: (none)"
        end

        queued = status["queued"] || []
        lines << ""
        lines << "Queued (#{queued.length}):"
        if queued.empty?
          lines << "  (none)"
        else
          queued.each { |name| lines << "  #{name}" }
        end

        finished = status["finished"] || []
        lines << ""
        lines << "Finished (#{finished.length}):"
        if finished.empty?
          lines << "  (none)"
        else
          finished.each { |name| lines << "  #{name}" }
        end

        lines.join("\n")
      end
    end
  end
end
