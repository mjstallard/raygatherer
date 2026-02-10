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
          metadata: { "analyzers" => [nil, { "name" => "Analyzer A" }] },
          rows: [
            { "packet_timestamp" => "2024-02-07T14:25:32Z", "events" => [nil, { "event_type" => "Informational", "message" => "Info" }] }
          ]
        })

        exit_code = described_class.run(["--host", host], stdout: stdout, stderr: stderr)

        expect(stdout.string).to include("No alerts detected")
        expect(exit_code).to eq(0)
      end

      it "extracts and displays Low severity alert with analyzer name" do
        allow(api_client).to receive(:fetch_live_analysis_report).and_return({
          metadata: { "analyzers" => [nil, { "name" => "Analyzer A" }] },
          rows: [
            { "packet_timestamp" => "2024-02-07T14:25:32Z", "events" => [nil, { "event_type" => "Low", "message" => "Low severity issue" }] }
          ]
        })

        exit_code = described_class.run(["--host", host], stdout: stdout, stderr: stderr)

        expect(stdout.string).to include("Low severity alert detected")
        expect(stdout.string).to include("Low severity issue")
        expect(stdout.string).to include("Analyzer A")
        expect(exit_code).to eq(10)
      end

      it "extracts and displays Medium severity alert" do
        allow(api_client).to receive(:fetch_live_analysis_report).and_return({
          metadata: { "analyzers" => [nil, { "name" => "Analyzer A" }] },
          rows: [
            { "packet_timestamp" => "2024-02-07T14:25:32Z", "events" => [nil, { "event_type" => "Medium", "message" => "Connection redirect" }] }
          ]
        })

        exit_code = described_class.run(["--host", host], stdout: stdout, stderr: stderr)

        expect(stdout.string).to include("Medium severity alert detected")
        expect(stdout.string).to include("Connection redirect")
        expect(exit_code).to eq(11)
      end

      it "extracts and displays High severity alert" do
        allow(api_client).to receive(:fetch_live_analysis_report).and_return({
          metadata: { "analyzers" => [nil, { "name" => "Analyzer A" }] },
          rows: [
            { "packet_timestamp" => "2024-02-07T14:25:32Z", "events" => [nil, { "event_type" => "High", "message" => "Critical threat" }] }
          ]
        })

        exit_code = described_class.run(["--host", host], stdout: stdout, stderr: stderr)

        expect(stdout.string).to include("High severity alert detected")
        expect(stdout.string).to include("Critical threat")
        expect(exit_code).to eq(12)
      end

      it "shows all alerts when multiple exist" do
        allow(api_client).to receive(:fetch_live_analysis_report).and_return({
          metadata: { "analyzers" => [nil, { "name" => "Analyzer A" }] },
          rows: [
            { "packet_timestamp" => "2024-02-07T14:25:32Z", "events" => [nil, { "event_type" => "Low", "message" => "Low issue" }] },
            { "packet_timestamp" => "2024-02-07T14:25:33Z", "events" => [nil, { "event_type" => "High", "message" => "High issue" }] },
            { "packet_timestamp" => "2024-02-07T14:25:34Z", "events" => [nil, { "event_type" => "Medium", "message" => "Medium issue" }] }
          ]
        })

        exit_code = described_class.run(["--host", host], stdout: stdout, stderr: stderr)

        expect(stdout.string).to include("Low issue")
        expect(stdout.string).to include("High issue")
        expect(stdout.string).to include("Medium issue")
        expect(exit_code).to eq(12)
      end

      it "handles multiple events in a single row" do
        allow(api_client).to receive(:fetch_live_analysis_report).and_return({
          metadata: { "analyzers" => [nil, { "name" => "Analyzer A" }, { "name" => "Analyzer B" }] },
          rows: [
            {
              "packet_timestamp" => "2024-02-07T14:25:32Z",
              "events" => [
                nil,
                { "event_type" => "Low", "message" => "Low issue" },
                { "event_type" => "Medium", "message" => "Medium issue" }
              ]
            }
          ]
        })

        exit_code = described_class.run(["--host", host], stdout: stdout, stderr: stderr)

        expect(stdout.string).to include("Low issue")
        expect(stdout.string).to include("Medium issue")
        expect(exit_code).to eq(11)
      end
    end

    describe "--latest flag" do
      let(:host) { "http://localhost:8080" }

      it "shows only alerts from the most recent packet_timestamp" do
        allow(api_client).to receive(:fetch_live_analysis_report).and_return({
          metadata: { "analyzers" => [nil, { "name" => "Analyzer A" }] },
          rows: [
            { "packet_timestamp" => "2024-02-07T14:25:32Z", "events" => [nil, { "event_type" => "High", "message" => "Old high alert" }] },
            { "packet_timestamp" => "2024-02-07T14:25:34Z", "events" => [nil, { "event_type" => "Low", "message" => "Latest low alert" }] },
            { "packet_timestamp" => "2024-02-07T14:25:33Z", "events" => [nil, { "event_type" => "Medium", "message" => "Middle medium alert" }] }
          ]
        })

        exit_code = described_class.run(["--host", host, "--latest"], stdout: stdout, stderr: stderr)

        expect(stdout.string).to include("Latest low alert")
        expect(stdout.string).not_to include("Old high alert")
        expect(stdout.string).not_to include("Middle medium alert")
        expect(exit_code).to eq(10)
      end

      it "exit code reflects latest message severity, not overall highest" do
        allow(api_client).to receive(:fetch_live_analysis_report).and_return({
          metadata: { "analyzers" => [nil, { "name" => "Analyzer A" }] },
          rows: [
            { "packet_timestamp" => "2024-02-07T14:25:32Z", "events" => [nil, { "event_type" => "High", "message" => "Old high" }] },
            { "packet_timestamp" => "2024-02-07T14:25:34Z", "events" => [nil, { "event_type" => "Low", "message" => "Latest low" }] }
          ]
        })

        exit_code = described_class.run(["--host", host, "--latest"], stdout: stdout, stderr: stderr)

        expect(exit_code).to eq(10)
      end

      it "--json --latest returns JSON array of latest alerts" do
        allow(api_client).to receive(:fetch_live_analysis_report).and_return({
          metadata: { "analyzers" => [nil, { "name" => "Analyzer A" }] },
          rows: [
            { "packet_timestamp" => "2024-02-07T14:25:32Z", "events" => [nil, { "event_type" => "High", "message" => "Old high" }] },
            { "packet_timestamp" => "2024-02-07T14:25:34Z", "events" => [nil, { "event_type" => "Low", "message" => "Latest low" }] }
          ]
        })

        exit_code = described_class.run(["--host", host, "--latest", "--json"], stdout: stdout, stderr: stderr)

        parsed = ::JSON.parse(stdout.string.strip)
        expect(parsed).to be_an(Array)
        expect(parsed.length).to eq(1)
        expect(parsed[0]["message"]).to eq("Latest low")
        expect(exit_code).to eq(10)
      end

      it "returns no alerts when latest row has only Informational events" do
        allow(api_client).to receive(:fetch_live_analysis_report).and_return({
          metadata: { "analyzers" => [nil, { "name" => "Analyzer A" }] },
          rows: [
            { "packet_timestamp" => "2024-02-07T14:25:32Z", "events" => [nil, { "event_type" => "High", "message" => "Old high" }] },
            { "packet_timestamp" => "2024-02-07T14:25:34Z", "events" => [nil, { "event_type" => "Informational", "message" => "Info only" }] }
          ]
        })

        exit_code = described_class.run(["--host", host, "--latest"], stdout: stdout, stderr: stderr)

        expect(stdout.string).to include("No alerts detected")
        expect(exit_code).to eq(0)
      end
    end

    describe "edge cases" do
      let(:host) { "http://localhost:8080" }

      it "handles missing analyzer name gracefully" do
        allow(api_client).to receive(:fetch_live_analysis_report).and_return({
          metadata: { "analyzers" => [nil] },
          rows: [
            { "packet_timestamp" => "2024-02-07T14:25:32Z", "events" => [nil, { "event_type" => "High", "message" => "Alert without analyzer" }] }
          ]
        })

        exit_code = described_class.run(["--host", host], stdout: stdout, stderr: stderr)

        expect(stdout.string).to include("Alert without analyzer")
        expect(stdout.string).not_to include("Analyzer:")
        expect(exit_code).to eq(12)
      end

      it "handles missing metadata gracefully" do
        allow(api_client).to receive(:fetch_live_analysis_report).and_return({
          metadata: {},
          rows: [
            { "packet_timestamp" => "2024-02-07T14:25:32Z", "events" => [nil, { "event_type" => "Low", "message" => "Alert no metadata" }] }
          ]
        })

        exit_code = described_class.run(["--host", host], stdout: stdout, stderr: stderr)

        expect(stdout.string).to include("Alert no metadata")
        expect(exit_code).to eq(10)
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

  describe "--json flag" do
    let(:stdout) { StringIO.new }
    let(:stderr) { StringIO.new }
    let(:api_client) { instance_double(Raygatherer::ApiClient) }
    let(:host) { "http://localhost:8080" }

    before do
      allow(Raygatherer::ApiClient).to receive(:new).and_return(api_client)
    end

    it "accepts --json flag" do
      allow(api_client).to receive(:fetch_live_analysis_report).and_return({
        metadata: {},
        rows: []
      })

      exit_code = described_class.run(
        ["--host", host, "--json"],
        stdout: stdout,
        stderr: stderr
      )

      expect(exit_code).to eq(0)
    end

    it "uses JSON formatter when --json is present" do
      allow(api_client).to receive(:fetch_live_analysis_report).and_return({
        metadata: { "analyzers" => [nil, { "name" => "Analyzer A" }] },
        rows: [{ "packet_timestamp" => "2024-02-07T14:25:32Z", "events" => [nil, { "event_type" => "High", "message" => "Test alert" }] }]
      })

      described_class.run(
        ["--host", host, "--json"],
        stdout: stdout,
        stderr: stderr
      )

      output = stdout.string.strip
      expect { ::JSON.parse(output) }.not_to raise_error

      parsed = ::JSON.parse(output)
      expect(parsed).to be_an(Array)
      expect(parsed.length).to eq(1)
      expect(parsed[0]["severity"]).to eq("High")
      expect(parsed[0]["message"]).to eq("Test alert")
      expect(parsed[0]["packet_timestamp"]).to eq("2024-02-07T14:25:32Z")
      expect(parsed[0]["analyzer"]).to eq("Analyzer A")
    end

    it "uses Human formatter when --json is absent (default)" do
      allow(api_client).to receive(:fetch_live_analysis_report).and_return({
        metadata: {},
        rows: []
      })

      described_class.run(
        ["--host", host],
        stdout: stdout,
        stderr: stderr
      )

      # Output should be human-readable (has color codes and emoji)
      output = stdout.string
      expect(output).to include("✓")
      expect(output).to include("No alerts detected")
    end

    it "--json and --verbose work together (JSON to stdout, verbose to stderr)" do
      allow(api_client).to receive(:fetch_live_analysis_report).and_return({
        metadata: {},
        rows: []
      })

      described_class.run(
        ["--host", host, "--json"],
        stdout: stdout,
        stderr: stderr,
        verbose: true
      )

      # JSON should go to stdout
      output = stdout.string.strip
      expect { ::JSON.parse(output) }.not_to raise_error

      # Verbose logs should go to stderr (tested in ApiClient specs)
    end

    it "JSON output goes to stdout (no colors, no emojis)" do
      allow(api_client).to receive(:fetch_live_analysis_report).and_return({
        metadata: { "analyzers" => [nil, { "name" => "Analyzer A" }] },
        rows: [{ "packet_timestamp" => "2024-02-07T14:25:32Z", "events" => [nil, { "event_type" => "High", "message" => "Test" }] }]
      })

      described_class.run(
        ["--host", host, "--json"],
        stdout: stdout,
        stderr: stderr
      )

      output = stdout.string.strip

      # Should be valid JSON array (no color codes or emojis)
      parsed = ::JSON.parse(output)
      expect(parsed).to be_an(Array)

      # Should not contain ANSI color codes
      expect(output).not_to match(/\e\[\d+m/)

      # Should not contain emojis (Human formatter uses ✓, 🚨, ⚠)
      expect(output).not_to include("✓")
      expect(output).not_to include("🚨")
      expect(output).not_to include("⚠")
    end
  end

  describe "severity-based exit codes" do
    let(:stdout) { StringIO.new }
    let(:stderr) { StringIO.new }
    let(:api_client) { instance_double(Raygatherer::ApiClient) }
    let(:host) { "http://localhost:8080" }

    before do
      allow(Raygatherer::ApiClient).to receive(:new).and_return(api_client)
    end

    it "returns 0 when no alerts" do
      allow(api_client).to receive(:fetch_live_analysis_report).and_return({
        metadata: { "analyzers" => [nil] },
        rows: [{ "packet_timestamp" => "2024-02-07T14:25:32Z", "events" => [nil] }]
      })

      exit_code = described_class.run(["--host", host], stdout: stdout, stderr: stderr)

      expect(exit_code).to eq(0)
    end

    it "returns 10 for Low severity alert" do
      allow(api_client).to receive(:fetch_live_analysis_report).and_return({
        metadata: { "analyzers" => [nil, { "name" => "Analyzer A" }] },
        rows: [{ "packet_timestamp" => "2024-02-07T14:25:32Z", "events" => [nil, { "event_type" => "Low", "message" => "Low issue" }] }]
      })

      exit_code = described_class.run(["--host", host], stdout: stdout, stderr: stderr)

      expect(exit_code).to eq(10)
    end

    it "returns 11 for Medium severity alert" do
      allow(api_client).to receive(:fetch_live_analysis_report).and_return({
        metadata: { "analyzers" => [nil, { "name" => "Analyzer A" }] },
        rows: [{ "packet_timestamp" => "2024-02-07T14:25:32Z", "events" => [nil, { "event_type" => "Medium", "message" => "Medium issue" }] }]
      })

      exit_code = described_class.run(["--host", host], stdout: stdout, stderr: stderr)

      expect(exit_code).to eq(11)
    end

    it "returns 12 for High severity alert" do
      allow(api_client).to receive(:fetch_live_analysis_report).and_return({
        metadata: { "analyzers" => [nil, { "name" => "Analyzer A" }] },
        rows: [{ "packet_timestamp" => "2024-02-07T14:25:32Z", "events" => [nil, { "event_type" => "High", "message" => "High issue" }] }]
      })

      exit_code = described_class.run(["--host", host], stdout: stdout, stderr: stderr)

      expect(exit_code).to eq(12)
    end

    it "returns 1 for ConnectionError" do
      allow(api_client).to receive(:fetch_live_analysis_report).and_raise(
        Raygatherer::ApiClient::ConnectionError, "Connection failed"
      )

      exit_code = described_class.run(["--host", host], stdout: stdout, stderr: stderr)

      expect(exit_code).to eq(1)
    end

    it "returns 1 for ParseError" do
      allow(api_client).to receive(:fetch_live_analysis_report).and_raise(
        Raygatherer::ApiClient::ParseError, "Invalid JSON"
      )

      exit_code = described_class.run(["--host", host], stdout: stdout, stderr: stderr)

      expect(exit_code).to eq(1)
    end

    it "returns 1 for other errors (missing --host)" do
      exit_code = described_class.run([], stdout: stdout, stderr: stderr)

      expect(exit_code).to eq(1)
    end
  end
end
