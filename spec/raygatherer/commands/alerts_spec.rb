# frozen_string_literal: true

RSpec.describe Raygatherer::Commands::Alerts do
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
        end
      end

      it "shows help with -h" do
        expect do
          described_class.run(["-h"], stdout: stdout, stderr: stderr)
        end.to raise_error(Raygatherer::CLI::EarlyExit) do |error|
          expect(error.exit_code).to eq(0)
        end
      end

      it "shows --after in help text" do
        expect do
          described_class.run(["--help"], stdout: stdout, stderr: stderr)
        end.to raise_error(Raygatherer::CLI::EarlyExit)

        expect(stdout.string).to include("--after")
      end
    end

    describe "fetching and displaying alerts" do
      it "outputs no alerts message when no events found" do
        allow(api_client).to receive(:fetch_live_analysis_report).and_return({
          metadata: {},
          rows: [
            {"packet_timestamp" => "2024-02-07T14:25:32Z", "events" => [nil]},
            {"packet_timestamp" => "2024-02-07T14:25:33Z", "events" => [nil]}
          ]
        })

        exit_code = described_class.run([], stdout: stdout, stderr: stderr, api_client: api_client)

        expect(stdout.string).to include("No alerts detected")
        expect(exit_code).to eq(0)
      end

      it "outputs no alerts message when only Informational events found" do
        allow(api_client).to receive(:fetch_live_analysis_report).and_return({
          metadata: {"analyzers" => [nil, {"name" => "Analyzer A"}]},
          rows: [
            {"packet_timestamp" => "2024-02-07T14:25:32Z", "events" => [nil, {"event_type" => "Informational", "message" => "Info"}]}
          ]
        })

        exit_code = described_class.run([], stdout: stdout, stderr: stderr, api_client: api_client)

        expect(stdout.string).to include("No alerts detected")
        expect(exit_code).to eq(0)
      end

      it "extracts and displays Low severity alert with analyzer name" do
        allow(api_client).to receive(:fetch_live_analysis_report).and_return({
          metadata: {"analyzers" => [nil, {"name" => "Analyzer A"}]},
          rows: [
            {"packet_timestamp" => "2024-02-07T14:25:32Z", "events" => [nil, {"event_type" => "Low", "message" => "Low severity issue"}]}
          ]
        })

        exit_code = described_class.run([], stdout: stdout, stderr: stderr, api_client: api_client)

        expect(stdout.string).to include("Low severity alert detected")
        expect(stdout.string).to include("Low severity issue")
        expect(stdout.string).to include("Analyzer A")
        expect(exit_code).to eq(10)
      end

      it "extracts and displays Medium severity alert" do
        allow(api_client).to receive(:fetch_live_analysis_report).and_return({
          metadata: {"analyzers" => [nil, {"name" => "Analyzer A"}]},
          rows: [
            {"packet_timestamp" => "2024-02-07T14:25:32Z", "events" => [nil, {"event_type" => "Medium", "message" => "Connection redirect"}]}
          ]
        })

        exit_code = described_class.run([], stdout: stdout, stderr: stderr, api_client: api_client)

        expect(stdout.string).to include("Medium severity alert detected")
        expect(stdout.string).to include("Connection redirect")
        expect(exit_code).to eq(11)
      end

      it "extracts and displays High severity alert" do
        allow(api_client).to receive(:fetch_live_analysis_report).and_return({
          metadata: {"analyzers" => [nil, {"name" => "Analyzer A"}]},
          rows: [
            {"packet_timestamp" => "2024-02-07T14:25:32Z", "events" => [nil, {"event_type" => "High", "message" => "Critical threat"}]}
          ]
        })

        exit_code = described_class.run([], stdout: stdout, stderr: stderr, api_client: api_client)

        expect(stdout.string).to include("High severity alert detected")
        expect(stdout.string).to include("Critical threat")
        expect(exit_code).to eq(12)
      end

      it "shows all alerts when multiple exist" do
        allow(api_client).to receive(:fetch_live_analysis_report).and_return({
          metadata: {"analyzers" => [nil, {"name" => "Analyzer A"}]},
          rows: [
            {"packet_timestamp" => "2024-02-07T14:25:32Z", "events" => [nil, {"event_type" => "Low", "message" => "Low issue"}]},
            {"packet_timestamp" => "2024-02-07T14:25:33Z", "events" => [nil, {"event_type" => "High", "message" => "High issue"}]},
            {"packet_timestamp" => "2024-02-07T14:25:34Z", "events" => [nil, {"event_type" => "Medium", "message" => "Medium issue"}]}
          ]
        })

        exit_code = described_class.run([], stdout: stdout, stderr: stderr, api_client: api_client)

        expect(stdout.string).to include("Low issue")
        expect(stdout.string).to include("High issue")
        expect(stdout.string).to include("Medium issue")
        expect(exit_code).to eq(12)
      end

      it "handles multiple events in a single row" do
        allow(api_client).to receive(:fetch_live_analysis_report).and_return({
          metadata: {"analyzers" => [nil, {"name" => "Analyzer A"}, {"name" => "Analyzer B"}]},
          rows: [
            {
              "packet_timestamp" => "2024-02-07T14:25:32Z",
              "events" => [
                nil,
                {"event_type" => "Low", "message" => "Low issue"},
                {"event_type" => "Medium", "message" => "Medium issue"}
              ]
            }
          ]
        })

        exit_code = described_class.run([], stdout: stdout, stderr: stderr, api_client: api_client)

        expect(stdout.string).to include("Low issue")
        expect(stdout.string).to include("Medium issue")
        expect(exit_code).to eq(11)
      end
    end

    describe "--latest flag" do
      it "shows only alerts from the most recent packet_timestamp" do
        allow(api_client).to receive(:fetch_live_analysis_report).and_return({
          metadata: {"analyzers" => [nil, {"name" => "Analyzer A"}]},
          rows: [
            {"packet_timestamp" => "2024-02-07T14:25:32Z", "events" => [nil, {"event_type" => "High", "message" => "Old high alert"}]},
            {"packet_timestamp" => "2024-02-07T14:25:34Z", "events" => [nil, {"event_type" => "Low", "message" => "Latest low alert"}]},
            {"packet_timestamp" => "2024-02-07T14:25:33Z", "events" => [nil, {"event_type" => "Medium", "message" => "Middle medium alert"}]}
          ]
        })

        exit_code = described_class.run(["--latest"], stdout: stdout, stderr: stderr, api_client: api_client)

        expect(stdout.string).to include("Latest low alert")
        expect(stdout.string).not_to include("Old high alert")
        expect(stdout.string).not_to include("Middle medium alert")
        expect(exit_code).to eq(10)
      end

      it "exit code reflects latest message severity, not overall highest" do
        allow(api_client).to receive(:fetch_live_analysis_report).and_return({
          metadata: {"analyzers" => [nil, {"name" => "Analyzer A"}]},
          rows: [
            {"packet_timestamp" => "2024-02-07T14:25:32Z", "events" => [nil, {"event_type" => "High", "message" => "Old high"}]},
            {"packet_timestamp" => "2024-02-07T14:25:34Z", "events" => [nil, {"event_type" => "Low", "message" => "Latest low"}]}
          ]
        })

        exit_code = described_class.run(["--latest"], stdout: stdout, stderr: stderr, api_client: api_client)

        expect(exit_code).to eq(10)
      end

      it "--json --latest returns JSON array of latest alerts" do
        allow(api_client).to receive(:fetch_live_analysis_report).and_return({
          metadata: {"analyzers" => [nil, {"name" => "Analyzer A"}]},
          rows: [
            {"packet_timestamp" => "2024-02-07T14:25:32Z", "events" => [nil, {"event_type" => "High", "message" => "Old high"}]},
            {"packet_timestamp" => "2024-02-07T14:25:34Z", "events" => [nil, {"event_type" => "Low", "message" => "Latest low"}]}
          ]
        })

        exit_code = described_class.run(["--latest"], stdout: stdout, stderr: stderr, api_client: api_client, json: true)

        parsed = ::JSON.parse(stdout.string.strip)
        expect(parsed).to be_an(Array)
        expect(parsed.length).to eq(1)
        expect(parsed[0]["message"]).to eq("Latest low")
        expect(exit_code).to eq(10)
      end

      it "returns no alerts when latest row has only Informational events" do
        allow(api_client).to receive(:fetch_live_analysis_report).and_return({
          metadata: {"analyzers" => [nil, {"name" => "Analyzer A"}]},
          rows: [
            {"packet_timestamp" => "2024-02-07T14:25:32Z", "events" => [nil, {"event_type" => "High", "message" => "Old high"}]},
            {"packet_timestamp" => "2024-02-07T14:25:34Z", "events" => [nil, {"event_type" => "Informational", "message" => "Info only"}]}
          ]
        })

        exit_code = described_class.run(["--latest"], stdout: stdout, stderr: stderr, api_client: api_client)

        expect(stdout.string).to include("No alerts detected")
        expect(exit_code).to eq(0)
      end
    end

    describe "--after flag" do
      it "shows only alerts after the given timestamp" do
        allow(api_client).to receive(:fetch_live_analysis_report).and_return({
          metadata: {"analyzers" => [nil, {"name" => "Analyzer A"}]},
          rows: [
            {"packet_timestamp" => "2024-02-07T14:25:32Z", "events" => [nil, {"event_type" => "Low", "message" => "Before alert"}]},
            {"packet_timestamp" => "2024-02-07T14:25:33Z", "events" => [nil, {"event_type" => "Medium", "message" => "At boundary alert"}]},
            {"packet_timestamp" => "2024-02-07T14:25:34Z", "events" => [nil, {"event_type" => "High", "message" => "After alert"}]}
          ]
        })

        exit_code = described_class.run(
          ["--after", "2024-02-07T14:25:33Z"],
          stdout: stdout, stderr: stderr, api_client: api_client
        )

        expect(stdout.string).to include("After alert")
        expect(stdout.string).not_to include("Before alert")
        expect(stdout.string).not_to include("At boundary alert")
        expect(exit_code).to eq(12)
      end

      it "composes with --latest to show only the latest alert after the timestamp" do
        allow(api_client).to receive(:fetch_live_analysis_report).and_return({
          metadata: {"analyzers" => [nil, {"name" => "Analyzer A"}]},
          rows: [
            {"packet_timestamp" => "2024-02-07T14:25:32Z", "events" => [nil, {"event_type" => "High", "message" => "Before cutoff"}]},
            {"packet_timestamp" => "2024-02-07T14:25:34Z", "events" => [nil, {"event_type" => "Low", "message" => "After cutoff early"}]},
            {"packet_timestamp" => "2024-02-07T14:25:36Z", "events" => [nil, {"event_type" => "Medium", "message" => "After cutoff latest"}]}
          ]
        })

        exit_code = described_class.run(
          ["--after", "2024-02-07T14:25:33Z", "--latest"],
          stdout: stdout, stderr: stderr, api_client: api_client
        )

        expect(stdout.string).to include("After cutoff latest")
        expect(stdout.string).not_to include("Before cutoff")
        expect(stdout.string).not_to include("After cutoff early")
        expect(exit_code).to eq(11)
      end

      it "--after --latest picks latest from filtered alerts, not all rows" do
        allow(api_client).to receive(:fetch_live_analysis_report).and_return({
          metadata: {"analyzers" => [nil, {"name" => "Analyzer A"}]},
          rows: [
            {"packet_timestamp" => "2024-02-07T14:25:32Z", "events" => [nil, {"event_type" => "High", "message" => "Old alert"}]},
            {"packet_timestamp" => "2024-02-07T14:25:34Z", "events" => [nil, {"event_type" => "Low", "message" => "New alert"}]},
            {"packet_timestamp" => "2024-02-07T14:25:36Z", "events" => [nil, {"event_type" => "Informational", "message" => "Info only"}]}
          ]
        })

        exit_code = described_class.run(
          ["--after", "2024-02-07T14:25:33Z", "--latest"],
          stdout: stdout, stderr: stderr, api_client: api_client
        )

        # --after filters to only the :34Z alert (excluding :32Z and :36Z informational)
        # --latest should pick from the filtered alerts, showing the :34Z alert
        expect(stdout.string).to include("New alert")
        expect(stdout.string).not_to include("Old alert")
        expect(exit_code).to eq(10)
      end

      it "returns no alerts when all alerts are before the timestamp" do
        allow(api_client).to receive(:fetch_live_analysis_report).and_return({
          metadata: {"analyzers" => [nil, {"name" => "Analyzer A"}]},
          rows: [
            {"packet_timestamp" => "2024-02-07T14:25:32Z", "events" => [nil, {"event_type" => "High", "message" => "Old alert"}]},
            {"packet_timestamp" => "2024-02-07T14:25:33Z", "events" => [nil, {"event_type" => "Low", "message" => "Also old"}]}
          ]
        })

        exit_code = described_class.run(
          ["--after", "2024-02-07T14:25:34Z"],
          stdout: stdout, stderr: stderr, api_client: api_client
        )

        expect(stdout.string).to include("No alerts detected")
        expect(exit_code).to eq(0)
      end

      it "returns error for invalid timestamp" do
        exit_code = described_class.run(
          ["--after", "not-a-timestamp"],
          stdout: stdout, stderr: stderr, api_client: api_client
        )

        expect(stderr.string).to include("invalid timestamp")
        expect(exit_code).to eq(1)
      end
    end

    describe "nil packet_timestamp" do
      it "excludes alerts with nil timestamp when --after is used" do
        allow(api_client).to receive(:fetch_live_analysis_report).and_return({
          metadata: {"analyzers" => [nil, {"name" => "Analyzer A"}]},
          rows: [
            {"packet_timestamp" => nil, "events" => [nil, {"event_type" => "High", "message" => "Nil timestamp alert"}]},
            {"packet_timestamp" => "2024-02-07T14:25:34Z", "events" => [nil, {"event_type" => "Low", "message" => "Valid alert"}]}
          ]
        })

        exit_code = described_class.run(
          ["--after", "2024-02-07T14:25:33Z"],
          stdout: stdout, stderr: stderr, api_client: api_client
        )

        expect(stdout.string).to include("Valid alert")
        expect(stdout.string).not_to include("Nil timestamp alert")
        expect(exit_code).to eq(10)
      end

      it "excludes alerts with nil timestamp when --latest is used" do
        allow(api_client).to receive(:fetch_live_analysis_report).and_return({
          metadata: {"analyzers" => [nil, {"name" => "Analyzer A"}]},
          rows: [
            {"packet_timestamp" => nil, "events" => [nil, {"event_type" => "High", "message" => "Nil timestamp alert"}]},
            {"packet_timestamp" => "2024-02-07T14:25:34Z", "events" => [nil, {"event_type" => "Low", "message" => "Valid alert"}]}
          ]
        })

        exit_code = described_class.run(
          ["--latest"],
          stdout: stdout, stderr: stderr, api_client: api_client
        )

        expect(stdout.string).to include("Valid alert")
        expect(stdout.string).not_to include("Nil timestamp alert")
        expect(exit_code).to eq(10)
      end

      it "handles mix of nil and non-nil timestamps with --after --latest" do
        allow(api_client).to receive(:fetch_live_analysis_report).and_return({
          metadata: {"analyzers" => [nil, {"name" => "Analyzer A"}]},
          rows: [
            {"packet_timestamp" => nil, "events" => [nil, {"event_type" => "High", "message" => "Nil ts"}]},
            {"packet_timestamp" => "2024-02-07T14:25:34Z", "events" => [nil, {"event_type" => "Low", "message" => "Earlier"}]},
            {"packet_timestamp" => "2024-02-07T14:25:36Z", "events" => [nil, {"event_type" => "Medium", "message" => "Latest valid"}]}
          ]
        })

        exit_code = described_class.run(
          ["--after", "2024-02-07T14:25:33Z", "--latest"],
          stdout: stdout, stderr: stderr, api_client: api_client
        )

        expect(stdout.string).to include("Latest valid")
        expect(stdout.string).not_to include("Nil ts")
        expect(stdout.string).not_to include("Earlier")
        expect(exit_code).to eq(11)
      end
    end

    describe "--recording flag" do
      it "fetches analysis report for a named recording" do
        allow(api_client).to receive(:fetch_analysis_report).with("my_recording").and_return({
          metadata: {"analyzers" => [nil, {"name" => "Analyzer A"}]},
          rows: [
            {"packet_timestamp" => "2024-02-07T14:25:32Z", "events" => [nil, {"event_type" => "Low", "message" => "Test alert"}]}
          ]
        })

        exit_code = described_class.run(
          ["--recording", "my_recording"],
          stdout: stdout, stderr: stderr, api_client: api_client
        )

        expect(stdout.string).to include("Test alert")
        expect(exit_code).to eq(10)
      end

      it "uses fetch_live_analysis_report when --recording is not provided" do
        allow(api_client).to receive(:fetch_live_analysis_report).and_return({
          metadata: {},
          rows: []
        })

        described_class.run([], stdout: stdout, stderr: stderr, api_client: api_client)

        expect(api_client).to have_received(:fetch_live_analysis_report)
      end

      it "composes with --latest" do
        allow(api_client).to receive(:fetch_analysis_report).with("rec1").and_return({
          metadata: {"analyzers" => [nil, {"name" => "Analyzer A"}]},
          rows: [
            {"packet_timestamp" => "2024-02-07T14:25:32Z", "events" => [nil, {"event_type" => "High", "message" => "Old alert"}]},
            {"packet_timestamp" => "2024-02-07T14:25:34Z", "events" => [nil, {"event_type" => "Low", "message" => "Latest alert"}]}
          ]
        })

        exit_code = described_class.run(
          ["--recording", "rec1", "--latest"],
          stdout: stdout, stderr: stderr, api_client: api_client
        )

        expect(stdout.string).to include("Latest alert")
        expect(stdout.string).not_to include("Old alert")
        expect(exit_code).to eq(10)
      end

      it "composes with --after" do
        allow(api_client).to receive(:fetch_analysis_report).with("rec1").and_return({
          metadata: {"analyzers" => [nil, {"name" => "Analyzer A"}]},
          rows: [
            {"packet_timestamp" => "2024-02-07T14:25:32Z", "events" => [nil, {"event_type" => "Low", "message" => "Before alert"}]},
            {"packet_timestamp" => "2024-02-07T14:25:34Z", "events" => [nil, {"event_type" => "High", "message" => "After alert"}]}
          ]
        })

        exit_code = described_class.run(
          ["--recording", "rec1", "--after", "2024-02-07T14:25:33Z"],
          stdout: stdout, stderr: stderr, api_client: api_client
        )

        expect(stdout.string).to include("After alert")
        expect(stdout.string).not_to include("Before alert")
        expect(exit_code).to eq(12)
      end

      it "composes with --json" do
        allow(api_client).to receive(:fetch_analysis_report).with("rec1").and_return({
          metadata: {"analyzers" => [nil, {"name" => "Analyzer A"}]},
          rows: [
            {"packet_timestamp" => "2024-02-07T14:25:32Z", "events" => [nil, {"event_type" => "Low", "message" => "Test alert"}]}
          ]
        })

        exit_code = described_class.run(
          ["--recording", "rec1"],
          stdout: stdout, stderr: stderr, api_client: api_client, json: true
        )

        parsed = ::JSON.parse(stdout.string.strip)
        expect(parsed).to be_an(Array)
        expect(parsed.length).to eq(1)
        expect(parsed[0]["message"]).to eq("Test alert")
        expect(exit_code).to eq(10)
      end

      it "shows --recording in help text" do
        expect do
          described_class.run(["--help"], stdout: stdout, stderr: stderr)
        end.to raise_error(Raygatherer::CLI::EarlyExit)

        expect(stdout.string).to include("--recording")
      end
    end

    describe "edge cases" do
      it "handles missing analyzer name gracefully" do
        allow(api_client).to receive(:fetch_live_analysis_report).and_return({
          metadata: {"analyzers" => [nil]},
          rows: [
            {"packet_timestamp" => "2024-02-07T14:25:32Z", "events" => [nil, {"event_type" => "High", "message" => "Alert without analyzer"}]}
          ]
        })

        exit_code = described_class.run([], stdout: stdout, stderr: stderr, api_client: api_client)

        expect(stdout.string).to include("Alert without analyzer")
        expect(stdout.string).not_to include("Analyzer:")
        expect(exit_code).to eq(12)
      end

      it "handles missing metadata gracefully" do
        allow(api_client).to receive(:fetch_live_analysis_report).and_return({
          metadata: {},
          rows: [
            {"packet_timestamp" => "2024-02-07T14:25:32Z", "events" => [nil, {"event_type" => "Low", "message" => "Alert no metadata"}]}
          ]
        })

        exit_code = described_class.run([], stdout: stdout, stderr: stderr, api_client: api_client)

        expect(stdout.string).to include("Alert no metadata")
        expect(exit_code).to eq(10)
      end
    end

    describe "error handling" do
      it "handles API errors gracefully" do
        allow(api_client).to receive(:fetch_live_analysis_report).and_raise(
          Raygatherer::ApiClient::ApiError, "Server error"
        )

        exit_code = described_class.run([], stdout: stdout, stderr: stderr, api_client: api_client)

        expect(stderr.string).to include("Error: Server error")
        expect(exit_code).to eq(1)
      end

      it "handles connection errors gracefully" do
        allow(api_client).to receive(:fetch_live_analysis_report).and_raise(
          Raygatherer::ApiClient::ConnectionError, "Connection failed"
        )

        exit_code = described_class.run([], stdout: stdout, stderr: stderr, api_client: api_client)

        expect(stderr.string).to include("Error: Connection failed")
        expect(exit_code).to eq(1)
      end

      it "handles parse errors gracefully" do
        allow(api_client).to receive(:fetch_live_analysis_report).and_raise(
          Raygatherer::ApiClient::ParseError, "Invalid JSON"
        )

        exit_code = described_class.run([], stdout: stdout, stderr: stderr, api_client: api_client)

        expect(stderr.string).to include("Error: Invalid JSON")
        expect(exit_code).to eq(1)
      end
    end
  end

  describe "json param" do
    let(:stdout) { StringIO.new }
    let(:stderr) { StringIO.new }
    let(:api_client) { instance_double(Raygatherer::ApiClient) }

    it "accepts json param" do
      allow(api_client).to receive(:fetch_live_analysis_report).and_return({
        metadata: {},
        rows: []
      })

      exit_code = described_class.run([],
        stdout: stdout, stderr: stderr,
        api_client: api_client, json: true)

      expect(exit_code).to eq(0)
    end

    it "uses JSON formatter when json: true" do
      allow(api_client).to receive(:fetch_live_analysis_report).and_return({
        metadata: {"analyzers" => [nil, {"name" => "Analyzer A"}]},
        rows: [{"packet_timestamp" => "2024-02-07T14:25:32Z", "events" => [nil, {"event_type" => "High", "message" => "Test alert"}]}]
      })

      described_class.run([],
        stdout: stdout, stderr: stderr,
        api_client: api_client, json: true)

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

    it "uses Human formatter when json: false (default)" do
      allow(api_client).to receive(:fetch_live_analysis_report).and_return({
        metadata: {},
        rows: []
      })

      described_class.run([],
        stdout: stdout, stderr: stderr,
        api_client: api_client)

      # Output should be human-readable (has color codes and emoji)
      output = stdout.string
      expect(output).to include("\u2713")
      expect(output).to include("No alerts detected")
    end

    it "JSON output goes to stdout (no colors, no emojis)" do
      allow(api_client).to receive(:fetch_live_analysis_report).and_return({
        metadata: {"analyzers" => [nil, {"name" => "Analyzer A"}]},
        rows: [{"packet_timestamp" => "2024-02-07T14:25:32Z", "events" => [nil, {"event_type" => "High", "message" => "Test"}]}]
      })

      described_class.run([],
        stdout: stdout, stderr: stderr,
        api_client: api_client, json: true)

      output = stdout.string.strip

      # Should be valid JSON array (no color codes or emojis)
      parsed = ::JSON.parse(output)
      expect(parsed).to be_an(Array)

      # Should not contain ANSI color codes
      expect(output).not_to match(/\e\[\d+m/)

      # Should not contain emojis (Human formatter uses ✓, 🚨, ⚠)
      expect(output).not_to include("\u2713")
      expect(output).not_to include("\u{1F6A8}")
      expect(output).not_to include("\u26A0")
    end
  end

  describe "severity-based exit codes" do
    let(:stdout) { StringIO.new }
    let(:stderr) { StringIO.new }
    let(:api_client) { instance_double(Raygatherer::ApiClient) }

    it "returns 0 when no alerts" do
      allow(api_client).to receive(:fetch_live_analysis_report).and_return({
        metadata: {"analyzers" => [nil]},
        rows: [{"packet_timestamp" => "2024-02-07T14:25:32Z", "events" => [nil]}]
      })

      exit_code = described_class.run([], stdout: stdout, stderr: stderr, api_client: api_client)

      expect(exit_code).to eq(0)
    end

    it "returns 10 for Low severity alert" do
      allow(api_client).to receive(:fetch_live_analysis_report).and_return({
        metadata: {"analyzers" => [nil, {"name" => "Analyzer A"}]},
        rows: [{"packet_timestamp" => "2024-02-07T14:25:32Z", "events" => [nil, {"event_type" => "Low", "message" => "Low issue"}]}]
      })

      exit_code = described_class.run([], stdout: stdout, stderr: stderr, api_client: api_client)

      expect(exit_code).to eq(10)
    end

    it "returns 11 for Medium severity alert" do
      allow(api_client).to receive(:fetch_live_analysis_report).and_return({
        metadata: {"analyzers" => [nil, {"name" => "Analyzer A"}]},
        rows: [{"packet_timestamp" => "2024-02-07T14:25:32Z", "events" => [nil, {"event_type" => "Medium", "message" => "Medium issue"}]}]
      })

      exit_code = described_class.run([], stdout: stdout, stderr: stderr, api_client: api_client)

      expect(exit_code).to eq(11)
    end

    it "returns 12 for High severity alert" do
      allow(api_client).to receive(:fetch_live_analysis_report).and_return({
        metadata: {"analyzers" => [nil, {"name" => "Analyzer A"}]},
        rows: [{"packet_timestamp" => "2024-02-07T14:25:32Z", "events" => [nil, {"event_type" => "High", "message" => "High issue"}]}]
      })

      exit_code = described_class.run([], stdout: stdout, stderr: stderr, api_client: api_client)

      expect(exit_code).to eq(12)
    end

    it "returns 1 for ConnectionError" do
      allow(api_client).to receive(:fetch_live_analysis_report).and_raise(
        Raygatherer::ApiClient::ConnectionError, "Connection failed"
      )

      exit_code = described_class.run([], stdout: stdout, stderr: stderr, api_client: api_client)

      expect(exit_code).to eq(1)
    end

    it "returns 1 for ParseError" do
      allow(api_client).to receive(:fetch_live_analysis_report).and_raise(
        Raygatherer::ApiClient::ParseError, "Invalid JSON"
      )

      exit_code = described_class.run([], stdout: stdout, stderr: stderr, api_client: api_client)

      expect(exit_code).to eq(1)
    end
  end
end
