# frozen_string_literal: true

module Raygatherer
  VERSION = "0.2.0"

  # The rayhunter daemon version this release was last verified against. Used only to warn
  # when talking to an older daemon that may lack fields/endpoints raygatherer expects;
  # never enforced.
  TESTED_RAYHUNTER_VERSION = "0.12.0"
end
