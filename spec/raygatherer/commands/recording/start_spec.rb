# frozen_string_literal: true

RSpec.describe Raygatherer::Commands::Recording::Start do
  describe ".run" do
    include_context "command context"

    it_behaves_like "a command with help", "recording start"

    describe "starting a recording" do
      it "errors if a name is provided" do
        exit_code = described_class.run(
          ["myrecording"],
          stdout: stdout, stderr: stderr, api_client: api_client
        )

        expect(stderr.string).to include("Error: recording start does not take a name")
        expect(exit_code).to eq(1)
      end

      it "calls start_recording" do
        expect(api_client).to receive(:start_recording)

        exit_code = described_class.run(
          [],
          stdout: stdout, stderr: stderr, api_client: api_client
        )

        expect(exit_code).to eq(0)
      end

      it "prints confirmation on success" do
        allow(api_client).to receive(:start_recording)

        exit_code = described_class.run(
          [],
          stdout: stdout, stderr: stderr, api_client: api_client
        )

        expect(stdout.string).to include("Recording started")
        expect(exit_code).to eq(0)
      end

      it "handles API errors" do
        allow(api_client).to receive(:start_recording).and_raise(
          Raygatherer::ApiClient::ApiError, "Server returned 500: Internal Server Error"
        )

        exit_code = described_class.run(
          [],
          stdout: stdout, stderr: stderr, api_client: api_client
        )

        expect(stderr.string).to include("Error: Server returned 500")
        expect(exit_code).to eq(1)
      end

      it "handles connection errors" do
        allow(api_client).to receive(:start_recording).and_raise(
          Raygatherer::ApiClient::ConnectionError, "Failed to connect"
        )

        exit_code = described_class.run(
          [],
          stdout: stdout, stderr: stderr, api_client: api_client
        )

        expect(stderr.string).to include("Error: Failed to connect")
        expect(exit_code).to eq(1)
      end
    end
  end
end
