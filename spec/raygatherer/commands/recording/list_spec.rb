# frozen_string_literal: true

RSpec.describe Raygatherer::Commands::Recording::List do
  describe ".run" do
    let(:stdout) { StringIO.new }
    let(:stderr) { StringIO.new }
    let(:api_client) { instance_double(Raygatherer::ApiClient) }

    describe "--help flag" do
      it "shows help with --help" do
        expect do
          described_class.run(["--help"], stdout: stdout, stderr: stderr)
        end.to raise_error(Raygatherer::CLI::EarlyExit) do |error|
          expect(error.exit_code).to eq(0)
          expect(stdout.string).to include("Usage:")
          expect(stdout.string).to include("recording list")
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

    describe "fetching and displaying recordings" do
      it "outputs 'No recordings found' when manifest is empty" do
        allow(api_client).to receive(:fetch_manifest).and_return({
          "entries" => [], "current_entry" => nil
        })

        exit_code = described_class.run([], stdout: stdout, stderr: stderr, api_client: api_client)

        expect(stdout.string).to include("No recordings found")
        expect(exit_code).to eq(0)
      end

      it "outputs recording entries in human format by default" do
        allow(api_client).to receive(:fetch_manifest).and_return({
          "entries" => [
            { "name" => "1738950000", "start_time" => "2025-02-07T13:40:00+00:00",
              "last_message_time" => "2025-02-07T15:30:00+00:00", "qmdl_size_bytes" => 134_963_200 }
          ],
          "current_entry" => nil
        })

        exit_code = described_class.run([], stdout: stdout, stderr: stderr, api_client: api_client)

        expect(stdout.string).to include("Recordings: 1")
        expect(stdout.string).to include("1738950000")
        expect(exit_code).to eq(0)
      end

      it "outputs JSON when json: true" do
        manifest = {
          "entries" => [
            { "name" => "1738950000", "start_time" => "2025-02-07T13:40:00+00:00",
              "last_message_time" => "2025-02-07T15:30:00+00:00", "qmdl_size_bytes" => 134_963_200 }
          ],
          "current_entry" => nil
        }
        allow(api_client).to receive(:fetch_manifest).and_return(manifest)

        exit_code = described_class.run([], stdout: stdout, stderr: stderr, api_client: api_client, json: true)

        parsed = ::JSON.parse(stdout.string.strip)
        expect(parsed["entries"].length).to eq(1)
        expect(parsed["entries"].first["name"]).to eq("1738950000")
        expect(exit_code).to eq(0)
      end
    end

    describe "error handling" do
      it "handles connection errors gracefully" do
        allow(api_client).to receive(:fetch_manifest).and_raise(
          Raygatherer::ApiClient::ConnectionError, "Connection failed"
        )

        exit_code = described_class.run([], stdout: stdout, stderr: stderr, api_client: api_client)

        expect(stderr.string).to include("Error: Connection failed")
        expect(exit_code).to eq(1)
      end

      it "handles API errors gracefully" do
        allow(api_client).to receive(:fetch_manifest).and_raise(
          Raygatherer::ApiClient::ApiError, "Server error"
        )

        exit_code = described_class.run([], stdout: stdout, stderr: stderr, api_client: api_client)

        expect(stderr.string).to include("Error: Server error")
        expect(exit_code).to eq(1)
      end

      it "handles parse errors gracefully" do
        allow(api_client).to receive(:fetch_manifest).and_raise(
          Raygatherer::ApiClient::ParseError, "Invalid JSON"
        )

        exit_code = described_class.run([], stdout: stdout, stderr: stderr, api_client: api_client)

        expect(stderr.string).to include("Error: Invalid JSON")
        expect(exit_code).to eq(1)
      end
    end
  end
end
