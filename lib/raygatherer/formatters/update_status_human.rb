# frozen_string_literal: true

module Raygatherer
  module Formatters
    class UpdateStatusHuman
      def format(status)
        lines = []

        lines << "Current version: #{status["current_version"]}"
        lines << "Update available: #{status["update_available"] ? "yes" : "no"}"
        lines << "Latest version: #{status["latest_version"]}" if status["latest_version"]
        lines << "Release notes: #{status["latest_release_url"]}" if status["latest_release_url"]
        lines << "Last checked: #{status["last_checked"]}" if status["last_checked"]
        lines << "Last error: #{status["last_error"]}" if status["last_error"]

        if status["latest_version"].nil? && status["last_checked"].nil?
          lines << ""
          lines << "No update check has run yet — check that auto_check_updates is enabled in rayhunter's config."
        end

        lines.join("\n")
      end
    end
  end
end
