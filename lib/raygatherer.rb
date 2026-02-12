# frozen_string_literal: true

require_relative "raygatherer/version"
require_relative "raygatherer/cli"
require_relative "raygatherer/api_client"
require_relative "raygatherer/formatters/human"
require_relative "raygatherer/formatters/json"
require_relative "raygatherer/formatters/recording_list_json"
require_relative "raygatherer/formatters/recording_list_human"
require_relative "raygatherer/formatters/stats_json"
require_relative "raygatherer/formatters/stats_human"
require_relative "raygatherer/spinner"
require_relative "raygatherer/commands/alert/status"
require_relative "raygatherer/commands/recording/list"
require_relative "raygatherer/commands/recording/download"
require_relative "raygatherer/commands/recording/delete"
require_relative "raygatherer/commands/recording/stop"
require_relative "raygatherer/commands/stats"

module Raygatherer
  class Error < StandardError; end
  # Your code goes here...
end
