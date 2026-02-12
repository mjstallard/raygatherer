# frozen_string_literal: true

require "tmpdir"

RSpec.describe Raygatherer::Commands::Recording::Download do
  describe ".run" do
    let(:stdout) { StringIO.new }
    let(:stderr) { StringIO.new }
    let(:api_client) { instance_double(Raygatherer::ApiClient) }
    let(:binary_content) { "\x00\x01\x02\x03\x04".b }
    let(:tmpdir) { Dir.mktmpdir }

    after { FileUtils.remove_entry(tmpdir) }

    describe "--help flag" do
      it "shows help with --help" do
        expect do
          described_class.run(["--help"], stdout: stdout, stderr: stderr)
        end.to raise_error(Raygatherer::CLI::EarlyExit) do |error|
          expect(error.exit_code).to eq(0)
          expect(stdout.string).to include("Usage:")
          expect(stdout.string).to include("recording download")
        end
      end

      it "shows help with -h" do
        expect do
          described_class.run(["-h"], stdout: stdout, stderr: stderr)
        end.to raise_error(Raygatherer::CLI::EarlyExit) do |error|
          expect(error.exit_code).to eq(0)
        end
      end
    end

    describe "downloading a recording" do
      around do |example|
        Dir.chdir(tmpdir) { example.run }
      end

      it "downloads qmdl to current dir, writes file, prints path and size" do
        allow(api_client).to receive(:download_recording) do |_name, **kwargs|
          kwargs[:io].write(binary_content)
        end

        exit_code = described_class.run(
          ["myrecording"],
          stdout: stdout, stderr: stderr, api_client: api_client
        )

        expected_path = File.join(".", "myrecording.qmdl")
        expect(File.exist?(expected_path)).to be true
        expect(File.binread(expected_path)).to eq(binary_content)
        expect(stdout.string).to include("myrecording.qmdl")
        expect(stdout.string).to include("5 B")
        expect(exit_code).to eq(0)
      end

      it "errors with message when no name argument given" do
        exit_code = described_class.run(
          [],
          stdout: stdout, stderr: stderr, api_client: api_client
        )

        expect(stderr.string).to include("Error: recording name is required")
        expect(exit_code).to eq(1)
      end

      it "errors when file already exists" do
        File.write("myrecording.qmdl", "existing data")

        exit_code = described_class.run(
          ["myrecording"],
          stdout: stdout, stderr: stderr, api_client: api_client
        )

        expect(stderr.string).to include("Error: file already exists")
        expect(exit_code).to eq(1)
      end

      it "handles API errors" do
        allow(api_client).to receive(:download_recording).and_raise(
          Raygatherer::ApiClient::ApiError, "Server returned 404: Not Found"
        )

        exit_code = described_class.run(
          ["myrecording"],
          stdout: stdout, stderr: stderr, api_client: api_client
        )

        expect(stderr.string).to include("Error: Server returned 404")
        expect(exit_code).to eq(1)
      end

      it "handles connection errors" do
        allow(api_client).to receive(:download_recording).and_raise(
          Raygatherer::ApiClient::ConnectionError, "Failed to connect"
        )

        exit_code = described_class.run(
          ["myrecording"],
          stdout: stdout, stderr: stderr, api_client: api_client
        )

        expect(stderr.string).to include("Error: Failed to connect")
        expect(exit_code).to eq(1)
      end

      it "cleans up partial file on API error" do
        allow(api_client).to receive(:download_recording).and_raise(
          Raygatherer::ApiClient::ApiError, "Server returned 500: Internal Server Error"
        )

        described_class.run(
          ["myrecording"],
          stdout: stdout, stderr: stderr, api_client: api_client
        )

        expect(File.exist?("myrecording.qmdl")).to be false
      end
    end
  end
end
