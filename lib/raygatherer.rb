# frozen_string_literal: true

require_relative "raygatherer/version"
require_relative "raygatherer/config"
require_relative "raygatherer/cli"
require_relative "raygatherer/api_client"
require_relative "raygatherer/formatters/human"
require_relative "raygatherer/formatters/json"
require_relative "raygatherer/formatters/recording_list_json"
require_relative "raygatherer/formatters/recording_list_human"
require_relative "raygatherer/formatters/stats_json"
require_relative "raygatherer/formatters/stats_human"
require_relative "raygatherer/formatters/analysis_status_json"
require_relative "raygatherer/formatters/analysis_status_human"
require_relative "raygatherer/formatters/config_json"
require_relative "raygatherer/formatters/config_human"
require_relative "raygatherer/spinner"
require_relative "raygatherer/commands/base"
require_relative "raygatherer/commands/alerts"
require_relative "raygatherer/commands/recording/list"
require_relative "raygatherer/commands/recording/download"
require_relative "raygatherer/commands/recording/delete"
require_relative "raygatherer/commands/recording/stop"
require_relative "raygatherer/commands/recording/start"
require_relative "raygatherer/commands/stats"
require_relative "raygatherer/commands/analysis/status"
require_relative "raygatherer/commands/analysis/run"
require_relative "raygatherer/commands/config/show"
require_relative "raygatherer/commands/config/set"
require_relative "raygatherer/commands/config/test_notification"

module Raygatherer
  class Error < StandardError; end
end
