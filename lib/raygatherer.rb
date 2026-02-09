# frozen_string_literal: true

require_relative "raygatherer/version"
require_relative "raygatherer/cli"
require_relative "raygatherer/api_client"
require_relative "raygatherer/formatters/human"
require_relative "raygatherer/commands/alert/status"

module Raygatherer
  class Error < StandardError; end
  # Your code goes here...
end
