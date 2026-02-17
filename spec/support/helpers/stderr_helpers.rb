# frozen_string_literal: true

module StderrHelpers
  def strip_ruby_warnings(output)
    output.lines.reject { |line| line.match?(/^\S+:\d+: warning:/) }.join
  end
end
