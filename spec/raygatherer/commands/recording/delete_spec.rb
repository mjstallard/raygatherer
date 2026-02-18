# frozen_string_literal: true

RSpec.describe Raygatherer::Commands::Recording::Delete do
  describe ".run" do
    let(:stdout) { StringIO.new }
    let(:stderr) { StringIO.new }
    let(:api_client) { instance_double(Raygatherer::ApiClient) }

    it_behaves_like "a command with help", "recording delete"

    describe "deleting all recordings" do
      it "calls delete_all_recordings with --all --force and prints success" do
        expect(api_client).to receive(:delete_all_recordings)

        exit_code = described_class.run(
          ["--all", "--force"],
          stdout: stdout, stderr: stderr, api_client: api_client
        )

        expect(stdout.string).to include("Deleted all recordings.")
        expect(exit_code).to eq(0)
      end

      it "prompts for confirmation on --all without --force and proceeds on 'y'" do
        stdin = StringIO.new("y\n")
        expect(api_client).to receive(:delete_all_recordings)

        exit_code = described_class.run(
          ["--all"],
          stdout: stdout, stderr: stderr, api_client: api_client, stdin: stdin
        )

        expect(stderr.string).to include("Are you sure?")
        expect(stdout.string).to include("Deleted all recordings.")
        expect(exit_code).to eq(0)
      end

      it "aborts on --all without --force when user answers 'n'" do
        stdin = StringIO.new("n\n")
        expect(api_client).not_to receive(:delete_all_recordings)

        exit_code = described_class.run(
          ["--all"],
          stdout: stdout, stderr: stderr, api_client: api_client, stdin: stdin
        )

        expect(stderr.string).to include("Aborted.")
        expect(exit_code).to eq(1)
      end

      it "aborts on --all without --force when user provides empty input" do
        stdin = StringIO.new("\n")
        expect(api_client).not_to receive(:delete_all_recordings)

        exit_code = described_class.run(
          ["--all"],
          stdout: stdout, stderr: stderr, api_client: api_client, stdin: stdin
        )

        expect(stderr.string).to include("Aborted.")
        expect(exit_code).to eq(1)
      end
    end

    describe "mutual exclusion" do
      it "errors when both a name and --all are given" do
        exit_code = described_class.run(
          ["myrecording", "--all"],
          stdout: stdout, stderr: stderr, api_client: api_client
        )

        expect(stderr.string).to include("Error: cannot specify both a recording name and --all")
        expect(exit_code).to eq(1)
      end
    end

    describe "deleting a recording" do
      it "requires a recording name" do
        exit_code = described_class.run(
          [],
          stdout: stdout, stderr: stderr, api_client: api_client
        )

        expect(stderr.string).to include("Error: recording name or --all is required")
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
