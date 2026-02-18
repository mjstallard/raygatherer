# frozen_string_literal: true

require "time"

module Raygatherer
  module Formatters
    class AnalysisReportHuman
      def format(data)
        metadata = data[:metadata] || {}
        rows = data[:rows] || []

        lines = []
        lines << format_header(metadata)
        lines << format_analyzers(metadata)
        lines << ""

        rows.each do |row|
          lines.concat(format_row(row, metadata))
        end

        lines.join("\n")
      end

      private

      def format_header(metadata)
        rayhunter = metadata["rayhunter"] || {}
        version = rayhunter["rayhunter_version"]
        os = rayhunter["system_os"]
        arch = rayhunter["arch"]
        report_version = metadata["report_version"]

        parts = []
        parts << "Rayhunter v#{version}" if version
        os_arch = [os, arch].compact.join(" ")
        parts << os_arch unless os_arch.empty?
        parts << "Report version #{report_version}" if report_version

        parts.join("  |  ")
      end

      def format_analyzers(metadata)
        analyzers = metadata["analyzers"] || []
        return "Analyzers: (none)" if analyzers.empty?

        names = analyzers.filter_map do |a|
          next unless a
          v = a["version"] ? " (v#{a["version"]})" : ""
          "#{a["name"]}#{v}"
        end

        "Analyzers: #{names.join(", ")}"
      end

      def format_row(row, metadata)
        analyzers = metadata["analyzers"] || []
        timestamp = format_timestamp(row["packet_timestamp"])

        if (reason = row["skipped_message_reason"])
          return ["#{timestamp}  Skipped: #{reason}"]
        end

        events = row["events"] || []
        non_nil = events.each_with_index.reject { |e, _| e.nil? }

        if non_nil.empty?
          return ["#{timestamp}  No events"]
        end

        non_nil.map do |event, index|
          event_type = event["event_type"] || "Unknown"
          message = event["message"]
          analyzer = analyzers.dig(index, "name")
          analyzer_part = analyzer ? "(#{analyzer}) " : ""
          "#{timestamp}  #{event_type.ljust(13)}  #{analyzer_part}#{message}"
        end
      end

      def format_timestamp(ts)
        return "[no timestamp]" unless ts
        time = Time.parse(ts).utc
        "[#{time.strftime("%Y-%m-%d %H:%M:%S UTC")}]"
      rescue ArgumentError
        "[#{ts}]"
      end
    end
  end
end
