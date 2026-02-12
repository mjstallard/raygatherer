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

      it "shows format flags in help" do
        expect do
          described_class.run(["--help"], stdout: stdout, stderr: stderr)
        end.to raise_error(Raygatherer::CLI::EarlyExit)

        expect(stdout.string).to include("--qmdl")
        expect(stdout.string).to include("--pcap")
        expect(stdout.string).to include("--zip")
      end

      it "shows path flags in help" do
        expect do
          described_class.run(["--help"], stdout: stdout, stderr: stderr)
        end.to raise_error(Raygatherer::CLI::EarlyExit)

        expect(stdout.string).to include("--download-dir")
        expect(stdout.string).to include("--save-as")
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

      it "downloads qmdl format with explicit --qmdl flag" do
        allow(api_client).to receive(:download_recording) do |name, **kwargs|
          expect(name).to eq("myrecording")
          expect(kwargs[:format]).to eq(:qmdl)
          kwargs[:io].write(binary_content)
        end

        exit_code = described_class.run(
          ["myrecording", "--qmdl"],
          stdout: stdout, stderr: stderr, api_client: api_client
        )

        expect(File.exist?("myrecording.qmdl")).to be true
        expect(stdout.string).to include("myrecording.qmdl")
        expect(exit_code).to eq(0)
      end

      it "downloads pcap format with --pcap flag" do
        allow(api_client).to receive(:download_recording) do |name, **kwargs|
          expect(name).to eq("myrecording")
          expect(kwargs[:format]).to eq(:pcap)
          kwargs[:io].write(binary_content)
        end

        exit_code = described_class.run(
          ["myrecording", "--pcap"],
          stdout: stdout, stderr: stderr, api_client: api_client
        )

        expect(File.exist?("myrecording.pcap")).to be true
        expect(stdout.string).to include("myrecording.pcap")
        expect(exit_code).to eq(0)
      end

      it "downloads zip format with --zip flag" do
        allow(api_client).to receive(:download_recording) do |name, **kwargs|
          expect(name).to eq("myrecording")
          expect(kwargs[:format]).to eq(:zip)
          kwargs[:io].write(binary_content)
        end

        exit_code = described_class.run(
          ["myrecording", "--zip"],
          stdout: stdout, stderr: stderr, api_client: api_client
        )

        expect(File.exist?("myrecording.zip")).to be true
        expect(stdout.string).to include("myrecording.zip")
        expect(exit_code).to eq(0)
      end

      it "errors when multiple format flags are given" do
        exit_code = described_class.run(
          ["myrecording", "--pcap", "--zip"],
          stdout: stdout, stderr: stderr, api_client: api_client
        )

        expect(stderr.string).to include("Error: only one format flag")
        expect(exit_code).to eq(1)
      end

      it "errors when --qmdl and --pcap are both given" do
        exit_code = described_class.run(
          ["myrecording", "--qmdl", "--pcap"],
          stdout: stdout, stderr: stderr, api_client: api_client
        )

        expect(stderr.string).to include("Error: only one format flag")
        expect(exit_code).to eq(1)
      end

      it "saves to specified directory with --download-dir" do
        allow(api_client).to receive(:download_recording) do |_name, **kwargs|
          kwargs[:io].write(binary_content)
        end

        subdir = File.join(tmpdir, "downloads")
        Dir.mkdir(subdir)

        exit_code = described_class.run(
          ["myrecording", "--download-dir", subdir],
          stdout: stdout, stderr: stderr, api_client: api_client
        )

        expected_path = File.join(subdir, "myrecording.qmdl")
        expect(File.exist?(expected_path)).to be true
        expect(stdout.string).to include(expected_path)
        expect(exit_code).to eq(0)
      end

      it "errors when --download-dir directory does not exist" do
        exit_code = described_class.run(
          ["myrecording", "--download-dir", "/nonexistent/path"],
          stdout: stdout, stderr: stderr, api_client: api_client
        )

        expect(stderr.string).to include("Error: directory does not exist")
        expect(exit_code).to eq(1)
      end

      it "saves to exact path with --save-as" do
        allow(api_client).to receive(:download_recording) do |_name, **kwargs|
          kwargs[:io].write(binary_content)
        end

        save_path = File.join(tmpdir, "custom_name.qmdl")

        exit_code = described_class.run(
          ["myrecording", "--save-as", save_path],
          stdout: stdout, stderr: stderr, api_client: api_client
        )

        expect(File.exist?(save_path)).to be true
        expect(stdout.string).to include(save_path)
        expect(exit_code).to eq(0)
      end

      it "errors when --save-as parent directory does not exist" do
        exit_code = described_class.run(
          ["myrecording", "--save-as", "/nonexistent/path/file.qmdl"],
          stdout: stdout, stderr: stderr, api_client: api_client
        )

        expect(stderr.string).to include("Error: directory does not exist")
        expect(exit_code).to eq(1)
      end

      it "errors when both --download-dir and --save-as are given" do
        exit_code = described_class.run(
          ["myrecording", "--download-dir", tmpdir, "--save-as", File.join(tmpdir, "file.qmdl")],
          stdout: stdout, stderr: stderr, api_client: api_client
        )

        expect(stderr.string).to include("Error: --download-dir and --save-as are mutually exclusive")
        expect(exit_code).to eq(1)
      end

      it "shows spinner on stderr during download" do
        allow(api_client).to receive(:download_recording) do |_name, **kwargs|
          sleep 0.2
          kwargs[:io].write(binary_content)
        end

        exit_code = described_class.run(
          ["myrecording"],
          stdout: stdout, stderr: stderr, api_client: api_client
        )

        expect(stderr.string).to include("Downloading...")
        expect(exit_code).to eq(0)
      end

      it "handles file permission errors gracefully" do
        allow(api_client).to receive(:download_recording)

        readonly_dir = File.join(tmpdir, "readonly")
        Dir.mkdir(readonly_dir)
        File.chmod(0o555, readonly_dir)

        exit_code = described_class.run(
          ["myrecording", "--download-dir", readonly_dir],
          stdout: stdout, stderr: stderr, api_client: api_client
        )

        expect(stderr.string).to include("Error:")
        expect(stderr.string).to include("Permission denied")
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
