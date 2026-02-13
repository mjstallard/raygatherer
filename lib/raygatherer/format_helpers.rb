# frozen_string_literal: true

module Raygatherer
  module FormatHelpers
    def format_size(bytes)
      return "0 B" unless bytes

      if bytes < 1024
        "#{bytes} B"
      elsif bytes < 1024 * 1024
        "#{Kernel.format('%.1f', bytes.to_f / 1024)} KB"
      elsif bytes < 1024 * 1024 * 1024
        "#{Kernel.format('%.1f', bytes.to_f / (1024 * 1024))} MB"
      else
        "#{Kernel.format('%.1f', bytes.to_f / (1024 * 1024 * 1024))} GB"
      end
    end
  end
end
