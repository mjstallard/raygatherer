# frozen_string_literal: true

RSpec.describe Raygatherer::Commands::Recording::Delete do
  describe ".run" do
    let(:stdout) { StringIO.new }
    let(:stderr) { StringIO.new }
    let(:api_client) { instance_double(Raygatherer::ApiClient) }

    it_behaves_like "a command with help", "recording delete"

    describe "deleting a recording" do
      it "requires a recording name" do
        exit_code = described_class.run(
          [],
          stdout: stdout, stderr: stderr, api_client: api_client
        )

        expect(stderr.string).to include("Error: recording name is required")
        expect(exit_code).to eq(1)
      end

      it "calls delete_recording with the name" do
        expect(api_client).to receive(:delete_recording).with("myrecording")

        exit_code = described_class.run(
          ["myrecording"],
          stdout: stdout, stderr: stderr, api_client: api_client
        )

        expect(exit_code).to eq(0)
      end

      it "prints confirmation on success" do
        allow(api_client).to receive(:delete_recording)

        exit_code = described_class.run(
          ["myrecording"],
          stdout: stdout, stderr: stderr, api_client: api_client
        )

        expect(stdout.string).to include("Deleted recording: myrecording")
        expect(exit_code).to eq(0)
      end

      it "handles API errors" do
        allow(api_client).to receive(:delete_recording).and_raise(
          Raygatherer::ApiClient::ApiError, "Server returned 400: Bad Request"
        )

        exit_code = described_class.run(
          ["myrecording"],
          stdout: stdout, stderr: stderr, api_client: api_client
        )

        expect(stderr.string).to include("Error: Server returned 400")
        expect(exit_code).to eq(1)
      end

      it "handles connection errors" do
        allow(api_client).to receive(:delete_recording).and_raise(
          Raygatherer::ApiClient::ConnectionError, "Failed to connect"
        )

        exit_code = described_class.run(
          ["myrecording"],
          stdout: stdout, stderr: stderr, api_client: api_client
        )

        expect(stderr.string).to include("Error: Failed to connect")
        expect(exit_code).to eq(1)
      end
    end
  end
end
