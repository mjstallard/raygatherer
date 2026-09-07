# frozen_string_literal: true

require_relative "raygatherer/version"
require_relative "raygatherer/config"
require_relative "raygatherer/api_client"
require_relative "raygatherer/spinner"
require_relative "raygatherer/commands/base"
require_relative "raygatherer/commands/alerts"
require_relative "raygatherer/commands/recording/list"
require_relative "raygatherer/commands/recording/download"
require_relative "raygatherer/commands/recording/delete"
require_relative "raygatherer/commands/recording/stop"
require_relative "raygatherer/commands/recording/start"
require_relative "raygatherer/commands/log"
require_relative "raygatherer/commands/stats"
require_relative "raygatherer/commands/analysis/status"
require_relative "raygatherer/commands/analysis/run"
require_relative "raygatherer/commands/analysis/report"
require_relative "raygatherer/commands/config/show"
require_relative "raygatherer/commands/config/set"
require_relative "raygatherer/commands/config/test_notification"
require_relative "raygatherer/commands/debug/display_state"
require_relative "raygatherer/commands/time/show"
require_relative "raygatherer/commands/time/sync"
require_relative "raygatherer/commands/update/status"
require_relative "raygatherer/commands/gps/show"
require_relative "raygatherer/commands/gps/set"
require_relative "raygatherer/commands/wifi/show"
require_relative "raygatherer/commands/wifi/scan"
require_relative "raygatherer/cli"

module Raygatherer
  class Error < StandardError; end
end
