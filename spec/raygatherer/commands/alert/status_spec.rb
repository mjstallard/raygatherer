# frozen_string_literal: true

RSpec.describe Raygatherer::Commands::Alert::Status do
  describe ".run" do
    let(:stdout) { StringIO.new }
    let(:stderr) { StringIO.new }
    let(:api_client) { instance_double(Raygatherer::ApiClient) }

    before do
      allow(Raygatherer::ApiClient).to receive(:new).and_return(api_client)
    end

    describe "--host flag" do
      it "requires --host flag" do
        exit_code = described_class.run([], stdout: stdout, stderr: stderr)

        expect(stderr.string).to include("--host is required")
        expect(exit_code).to eq(1)
      end

      it "shows help when --host is missing" do
        exit_code = described_class.run([], stdout: stdout, stderr: stderr)

        expect(stderr.string).to include("Usage:")
        expect(exit_code).to eq(1)
      end
    end

    describe "basic auth flags" do
      it "passes username and password to ApiClient" do
        allow(api_client).to receive(:fetch_live_analysis_report).and_return({
          metadata: {},
          rows: []
        })

        described_class.run([
          "--host", "http://test",
          "--basic-auth-user", "user",
          "--basic-auth-password", "pass"
        ], stdout: stdout, stderr: stderr)

        expect(Raygatherer::ApiClient).to have_received(:new).with(
          "http://test",
          username: "user",
          password: "pass",
          verbose: false,
          stderr: stderr
        )
      end

      it "works without username and password" do
        allow(api_client).to receive(:fetch_live_analysis_report).and_return({
          metadata: {},
          rows: []
        })

        described_class.run(["--host", "http://test"], stdout: stdout, stderr: stderr)

        expect(Raygatherer::ApiClient).to have_received(:new).with(
          "http://test",
          username: nil,
          password: nil,
          verbose: false,
          stderr: stderr
        )
      end
    end

    describe "verbose flag" do
      it "accepts verbose parameter and passes to ApiClient" do
        allow(api_client).to receive(:fetch_live_analysis_report).and_return({
          metadata: {},
          rows: []
        })

        described_class.run(
          ["--host", "http://test"],
          stdout: stdout,
          stderr: stderr,
          verbose: true
        )

        expect(Raygatherer::ApiClient).to have_received(:new).with(
          "http://test",
          username: nil,
          password: nil,
          verbose: true,
          stderr: stderr
        )
      end

      it "defaults verbose to false" do
        allow(api_client).to receive(:fetch_live_analysis_report).and_return({
          metadata: {},
          rows: []
        })

        described_class.run(["--host", "http://test"], stdout: stdout, stderr: stderr)

        expect(Raygatherer::ApiClient).to have_received(:new).with(
          "http://test",
          username: nil,
          password: nil,
          verbose: false,
          stderr: stderr
        )
      end
    end

    describe "--help flag" do
      it "shows help with --help" do
        expect do
          described_class.run(["--help"], stdout: stdout, stderr: stderr)
        end.to raise_error(Raygatherer::CLI::EarlyExit) do |error|
          expect(error.exit_code).to eq(0)
          expect(stdout.string).to include("Usage:")
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

    describe "fetching and displaying alerts" do
      let(:host) { "http://localhost:8080" }

      it "fetches data from API client with correct host" do
        allow(api_client).to receive(:fetch_live_analysis_report).and_return({
          metadata: {},
          rows: []
        })

        described_class.run(["--host", host], stdout: stdout, stderr: stderr)

        expect(Raygatherer::ApiClient).to have_received(:new).with(
          host,
          username: nil,
          password: nil,
          verbose: false,
          stderr: stderr
        )
      end

      it "outputs no alerts message when no events found" do
        allow(api_client).to receive(:fetch_live_analysis_report).and_return({
          metadata: {},
          rows: [
            { "packet_timestamp" => "2024-02-07T14:25:32Z", "events" => [nil] },
            { "packet_timestamp" => "2024-02-07T14:25:33Z", "events" => [nil] }
          ]
        })

        exit_code = described_class.run(["--host", host], stdout: stdout, stderr: stderr)

        expect(stdout.string).to include("No alerts detected")
        expect(exit_code).to eq(0)
      end

      it "outputs no alerts message when only Informational events found" do
        allow(api_client).to receive(:fetch_live_analysis_report).and_return({
          metadata: {},
          rows: [
            { "events" => [nil, { "event_type" => "Informational", "message" => "Info" }] }
          ]
        })

        exit_code = described_class.run(["--host", host], stdout: stdout, stderr: stderr)

        expect(stdout.string).to include("No alerts detected")
        expect(exit_code).to eq(0)
      end

      it "extracts and displays Low severity alert" do
        allow(api_client).to receive(:fetch_live_analysis_report).and_return({
          metadata: {},
          rows: [
            { "events" => [nil, { "event_type" => "Low", "message" => "Low severity issue" }] }
          ]
        })

        exit_code = described_class.run(["--host", host], stdout: stdout, stderr: stderr)

        expect(stdout.string).to include("Low severity alert detected")
        expect(stdout.string).to include("Low severity issue")
        expect(exit_code).to eq(0)
      end

      it "extracts and displays Medium severity alert" do
        allow(api_client).to receive(:fetch_live_analysis_report).and_return({
          metadata: {},
          rows: [
            { "events" => [nil, { "event_type" => "Medium", "message" => "Connection redirect" }] }
          ]
        })

        exit_code = described_class.run(["--host", host], stdout: stdout, stderr: stderr)

        expect(stdout.string).to include("Medium severity alert detected")
        expect(stdout.string).to include("Connection redirect")
        expect(exit_code).to eq(0)
      end

      it "extracts and displays High severity alert" do
        allow(api_client).to receive(:fetch_live_analysis_report).and_return({
          metadata: {},
          rows: [
            { "events" => [nil, { "event_type" => "High", "message" => "Critical threat" }] }
          ]
        })

        exit_code = described_class.run(["--host", host], stdout: stdout, stderr: stderr)

        expect(stdout.string).to include("High severity alert detected")
        expect(stdout.string).to include("Critical threat")
        expect(exit_code).to eq(0)
      end

      it "extracts highest severity alert when multiple alerts exist" do
        allow(api_client).to receive(:fetch_live_analysis_report).and_return({
          metadata: {},
          rows: [
            { "events" => [nil, { "event_type" => "Low", "message" => "Low issue" }] },
            { "events" => [nil, { "event_type" => "High", "message" => "High issue" }] },
            { "events" => [nil, { "event_type" => "Medium", "message" => "Medium issue" }] }
          ]
        })

        exit_code = described_class.run(["--host", host], stdout: stdout, stderr: stderr)

        expect(stdout.string).to include("High severity alert detected")
        expect(stdout.string).to include("High issue")
        expect(exit_code).to eq(0)
      end

      it "handles multiple events in a single row" do
        allow(api_client).to receive(:fetch_live_analysis_report).and_return({
          metadata: {},
          rows: [
            {
              "events" => [
                nil,
                { "event_type" => "Low", "message" => "Low issue" },
                { "event_type" => "Medium", "message" => "Medium issue" }
              ]
            }
          ]
        })

        exit_code = described_class.run(["--host", host], stdout: stdout, stderr: stderr)

        expect(stdout.string).to include("Medium severity alert detected")
        expect(exit_code).to eq(0)
      end
    end

    describe "error handling" do
      let(:host) { "http://localhost:8080" }

      it "handles API errors gracefully" do
        allow(api_client).to receive(:fetch_live_analysis_report).and_raise(
          Raygatherer::ApiClient::ApiError, "Server error"
        )

        exit_code = described_class.run(["--host", host], stdout: stdout, stderr: stderr)

        expect(stderr.string).to include("Error: Server error")
        expect(exit_code).to eq(1)
      end

      it "handles connection errors gracefully" do
        allow(api_client).to receive(:fetch_live_analysis_report).and_raise(
          Raygatherer::ApiClient::ConnectionError, "Connection failed"
        )

        exit_code = described_class.run(["--host", host], stdout: stdout, stderr: stderr)

        expect(stderr.string).to include("Error: Connection failed")
        expect(exit_code).to eq(1)
      end

      it "handles parse errors gracefully" do
        allow(api_client).to receive(:fetch_live_analysis_report).and_raise(
          Raygatherer::ApiClient::ParseError, "Invalid JSON"
        )

        exit_code = described_class.run(["--host", host], stdout: stdout, stderr: stderr)

        expect(stderr.string).to include("Error: Invalid JSON")
        expect(exit_code).to eq(1)
      end
    end
  end
end
