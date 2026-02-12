# frozen_string_literal: true

RSpec.describe Raygatherer::Spinner do
  let(:stderr) { StringIO.new }

  describe "#spin and #stop" do
    it "prints frames to stderr" do
      spinner = described_class.new(stderr: stderr)
      spinner.spin
      sleep 0.2
      spinner.stop

      expect(stderr.string).to include("Downloading...")
    end

    it "stops cleanly without error" do
      spinner = described_class.new(stderr: stderr)
      spinner.spin
      expect { spinner.stop }.not_to raise_error
    end

    it "clears the line after stopping" do
      spinner = described_class.new(stderr: stderr)
      spinner.spin
      sleep 0.2
      spinner.stop

      # After stop, the last thing written should clear the spinner line
      expect(stderr.string).to end_with("\r")
    end

    it "is safe to stop without starting" do
      spinner = described_class.new(stderr: stderr)
      expect { spinner.stop }.not_to raise_error
    end
  end
end
