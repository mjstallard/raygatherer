# frozen_string_literal: true

require "time"
require_relative "../format_helpers"

module Raygatherer
  module Formatters
    class RecordingListHuman
      include FormatHelpers

      def format(manifest)
        entries = manifest["entries"] || []
        current = manifest["current_entry"]
        total = entries.length + (current ? 1 : 0)

        return "No recordings found" if total == 0

        lines = []
        lines << header(total, current)
        lines << ""

        if current
          lines << format_entry(current, active: true)
          lines << ""
        end

        entries.each_with_index do |entry, index|
          lines << format_entry(entry, active: false)
          lines << "" unless index == entries.length - 1
        end

        lines.join("\n")
      end

      private

      def header(total, current)
        if current
          "Recordings: #{total} (1 active)"
        else
          "Recordings: #{total}"
        end
      end

      def format_entry(entry, active:)
        lines = []

        lines << if active
          "\u25CF #{entry["name"]} (recording)"
        else
          "  #{entry["name"]}"
        end

        lines << "  Started:      #{format_time(entry["start_time"])}"

        unless active
          lines << "  Last message: #{format_time(entry["last_message_time"])}"
        end

        lines << "  Size:         #{format_size(entry["qmdl_size_bytes"])}"

        if !active && entry["stop_reason"]
          lines << "  Stop reason:  #{entry["stop_reason"]}"
        end

        lines.join("\n")
      end

      def format_time(time_string)
        return "" unless time_string

        Time.parse(time_string).strftime("%Y-%m-%d %H:%M:%S")
      end
    end
  end
end
