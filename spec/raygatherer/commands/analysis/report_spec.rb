# frozen_string_literal: true

RSpec.describe Raygatherer::Commands::Analysis::Report do
  describe ".run" do
    include_context "command context"

    let(:analysis_report) do
      {
        metadata: {
          "analyzers" => [{"name" => "imsi_requested", "version" => 1}],
          "rayhunter" => {"rayhunter_version" => "1.2.3", "system_os" => "Linux", "arch" => "armv7l"},
          "report_version" => 2
        },
        rows: [
          {"packet_timestamp" => "2024-02-07T14:25:33Z", "events" => [nil]},
          {"packet_timestamp" => "2024-02-07T14:25:34Z", "events" => [{"event_type" => "Informational", "message" => "Some info"}]}
        ]
      }
    end

    it_behaves_like "a command with help", "analysis report"

    describe "argument validation" do
      it "requires a recording name or --live" do
        exit_code = described_class.run(
          [],
          stdout: stdout, stderr: stderr, api_client: api_client
        )

        expect(stderr.string).to include("recording name or --live is required")
        expect(exit_code).to eq(1)
      end
    end

    describe "--live flag" do
      it "calls fetch_live_analysis_report when --live is given" do
        allow(api_client).to receive(:fetch_live_analysis_report).and_return(analysis_report)

        exit_code = described_class.run(
          ["--live"],
          stdout: stdout, stderr: stderr, api_client: api_client
        )

        expect(api_client).to have_received(:fetch_live_analysis_report)
        expect(exit_code).to eq(0)
      end

      it "errors when --live and a name are both given" do
        exit_code = described_class.run(
          ["--live", "1738950000"],
          stdout: stdout, stderr: stderr, api_client: api_client
        )

        expect(stderr.string).to include("cannot use --live with a recording name")
        expect(exit_code).to eq(1)
      end
    end

    describe "fetching and displaying the report" do
      it "fetches the analysis report for the given name" do
        allow(api_client).to receive(:fetch_analysis_report).with("1738950000").and_return(analysis_report)

        exit_code = described_class.run(
          ["1738950000"],
          stdout: stdout, stderr: stderr, api_client: api_client
        )

        expect(exit_code).to eq(0)
        expect(api_client).to have_received(:fetch_analysis_report).with("1738950000")
      end

      it "shows header with rayhunter version and report version" do
        allow(api_client).to receive(:fetch_analysis_report).with("rec1").and_return(analysis_report)

        described_class.run(["rec1"], stdout: stdout, stderr: stderr, api_client: api_client)

        expect(stdout.string).to include("Rayhunter v1.2.3")
        expect(stdout.string).to include("Report version 2")
      end

      it "shows analyzer names with versions" do
        allow(api_client).to receive(:fetch_analysis_report).with("rec1").and_return(analysis_report)

        described_class.run(["rec1"], stdout: stdout, stderr: stderr, api_client: api_client)

        expect(stdout.string).to include("imsi_requested (v1)")
      end

      it "shows Informational events (unlike alerts)" do
        allow(api_client).to receive(:fetch_analysis_report).with("rec1").and_return(analysis_report)

        described_class.run(["rec1"], stdout: stdout, stderr: stderr, api_client: api_client)

        expect(stdout.string).to include("Informational")
        expect(stdout.string).to include("Some info")
      end

      it "shows 'No events' for rows with no events" do
        allow(api_client).to receive(:fetch_analysis_report).with("rec1").and_return(analysis_report)

        described_class.run(["rec1"], stdout: stdout, stderr: stderr, api_client: api_client)

        expect(stdout.string).to include("No events")
      end

      it "shows all severity levels" do
        report = {
          metadata: {
            "analyzers" => [{"name" => "analyzer_a", "version" => 1}, {"name" => "analyzer_b", "version" => 1}],
            "rayhunter" => {},
            "report_version" => 1
          },
          rows: [
            {
              "packet_timestamp" => "2024-02-07T14:25:32Z",
              "events" => [
                {"event_type" => "Low", "message" => "Low msg"},
                {"event_type" => "High", "message" => "High msg"}
              ]
            }
          ]
        }
        allow(api_client).to receive(:fetch_analysis_report).with("rec1").and_return(report)

        described_class.run(["rec1"], stdout: stdout, stderr: stderr, api_client: api_client)

        expect(stdout.string).to include("Low")
        expect(stdout.string).to include("Low msg")
        expect(stdout.string).to include("High")
        expect(stdout.string).to include("High msg")
      end

      it "shows skipped packet rows" do
        report = {
          metadata: {"analyzers" => [], "rayhunter" => {}, "report_version" => 1},
          rows: [
            {"packet_timestamp" => "2024-02-07T14:25:33Z", "skipped_message_reason" => "Unsupported message type"}
          ]
        }
        allow(api_client).to receive(:fetch_analysis_report).with("rec1").and_return(report)

        described_class.run(["rec1"], stdout: stdout, stderr: stderr, api_client: api_client)

        expect(stdout.string).to include("Skipped: Unsupported message type")
      end

      it "outputs JSON when json: true" do
        allow(api_client).to receive(:fetch_analysis_report).with("1738950000").and_return(analysis_report)

        exit_code = described_class.run(
          ["1738950000"],
          stdout: stdout, stderr: stderr, api_client: api_client, json: true
        )

        parsed = ::JSON.parse(stdout.string.strip)
        expect(parsed).to have_key("metadata")
        expect(parsed).to have_key("rows")
        expect(parsed["metadata"]["report_version"]).to eq(2)
        expect(parsed["rows"].length).to eq(2)
        expect(exit_code).to eq(0)
      end

      it "JSON output includes all rows including Informational" do
        allow(api_client).to receive(:fetch_analysis_report).with("rec1").and_return(analysis_report)

        described_class.run(["rec1"], stdout: stdout, stderr: stderr, api_client: api_client, json: true)

        parsed = ::JSON.parse(stdout.string.strip)
        informational_row = parsed["rows"].find { |r| r["events"]&.any? { |e| e&.dig("event_type") == "Informational" } }
        expect(informational_row).not_to be_nil
      end
    end

    it_behaves_like "command error handling",
      api_method: :fetch_analysis_report, run_args: ["rec1"]
  end
end
