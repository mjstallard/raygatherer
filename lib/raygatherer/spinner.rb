# frozen_string_literal: true

module Raygatherer
  class Spinner
    FRAMES = %w[* ** *** ** *].freeze

    def initialize(stderr: $stderr)
      @stderr = stderr
      @running = false
      @thread = nil
    end

    def spin
      @running = true
      @thread = Thread.new do
        i = 0
        while @running
          @stderr.print "\r#{FRAMES[i % FRAMES.length]} Downloading..."
          sleep 0.15
          i += 1
        end
        @stderr.print "\r#{' ' * 20}\r"
      end
    end

    def stop
      @running = false
      @thread&.join
    end
  end
end
