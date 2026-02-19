# frozen_string_literal: true

RSpec.describe Raygatherer::Commands::Recording::Stop do
  describe ".run" do
    include_context "command context"

    it_behaves_like "a command with help", "recording stop"

    describe "stopping a recording" do
      it "errors if a name is provided" do
        exit_code = described_class.run(
          ["myrecording"],
          stdout: stdout, stderr: stderr, api_client: api_client
        )

        expect(stderr.string).to include("Error: recording stop does not take a name")
        expect(exit_code).to eq(1)
      end

      it "calls stop_recording" do
        expect(api_client).to receive(:stop_recording)

        exit_code = described_class.run(
          [],
          stdout: stdout, stderr: stderr, api_client: api_client
        )

        expect(exit_code).to eq(0)
      end

      it "prints confirmation on success" do
        allow(api_client).to receive(:stop_recording)

        exit_code = described_class.run(
          [],
          stdout: stdout, stderr: stderr, api_client: api_client
        )

        expect(stdout.string).to include("Recording stopped")
        expect(exit_code).to eq(0)
      end

    end

    it_behaves_like "command error handling",
      api_method: :stop_recording, include_parse_error: false
  end
end
