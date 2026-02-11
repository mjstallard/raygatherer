# frozen_string_literal: true

module Raygatherer
  module Formatters
    class StatsHuman
      def format(stats)
        lines = []

        runtime = stats["runtime_metadata"] || {}
        lines << "Rayhunter v#{runtime['rayhunter_version']} | #{runtime['system_os']} | #{runtime['arch']}"
        lines << ""

        disk = stats["disk_stats"] || {}
        lines << "Disk: #{disk['used_size']} / #{disk['total_size']} (#{disk['used_percent']}) on #{disk['mounted_on']}"

        memory = stats["memory_stats"] || {}
        lines << "Memory: #{memory['used']} / #{memory['total']} (#{memory['free']} free)"

        battery = stats["battery_status"]
        if battery
          plug_status = battery["is_plugged_in"] ? "plugged in" : "on battery"
          lines << "Battery: #{battery['level']}% (#{plug_status})"
        end

        lines.join("\n")
      end
    end
  end
end
