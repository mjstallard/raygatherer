# frozen_string_literal: true

require "spec_helper"

RSpec.describe Raygatherer::Commands::Debug::DisplayState do
  let(:stdout) { StringIO.new }
  let(:stderr) { StringIO.new }
  let(:api_client) { instance_double(Raygatherer::ApiClient) }

  it_behaves_like "a command with help", "debug display-state"

  describe "recording state" do
    it "calls set_display_state with Recording JSON and prints success" do
      allow(api_client).to receive(:set_display_state).with('"Recording"')

      exit_code = described_class.run(["recording"], stdout: stdout, stderr: stderr, api_client: api_client)

      expect(api_client).to have_received(:set_display_state).with('"Recording"')
      expect(stdout.string).to include("Display state updated.")
      expect(exit_code).to eq(0)
    end
  end

  describe "paused state" do
    it "calls set_display_state with Paused JSON" do
      allow(api_client).to receive(:set_display_state).with('"Paused"')

      exit_code = described_class.run(["paused"], stdout: stdout, stderr: stderr, api_client: api_client)

      expect(api_client).to have_received(:set_display_state).with('"Paused"')
      expect(exit_code).to eq(0)
    end
  end

  describe "warning state" do
    it "calls set_display_state with WarningDetected JSON for high severity" do
      allow(api_client).to receive(:set_display_state).with('{"WarningDetected":{"event_type":"High"}}')

      exit_code = described_class.run(["warning", "--severity", "high"],
        stdout: stdout, stderr: stderr, api_client: api_client)

      expect(api_client).to have_received(:set_display_state).with('{"WarningDetected":{"event_type":"High"}}')
      expect(exit_code).to eq(0)
    end

    it "calls set_display_state with WarningDetected JSON for medium severity" do
      allow(api_client).to receive(:set_display_state).with('{"WarningDetected":{"event_type":"Medium"}}')

      exit_code = described_class.run(["warning", "--severity", "medium"],
        stdout: stdout, stderr: stderr, api_client: api_client)

      expect(api_client).to have_received(:set_display_state).with('{"WarningDetected":{"event_type":"Medium"}}')
      expect(exit_code).to eq(0)
    end

    it "calls set_display_state with WarningDetected JSON for low severity" do
      allow(api_client).to receive(:set_display_state).with('{"WarningDetected":{"event_type":"Low"}}')

      exit_code = described_class.run(["warning", "--severity", "low"],
        stdout: stdout, stderr: stderr, api_client: api_client)

      expect(api_client).to have_received(:set_display_state).with('{"WarningDetected":{"event_type":"Low"}}')
      expect(exit_code).to eq(0)
    end
  end

  describe "validation" do
    it "prints error and returns 1 when no state is given" do
      exit_code = described_class.run([], stdout: stdout, stderr: stderr, api_client: api_client)

      expect(stderr.string).to include("state must be one of")
      expect(exit_code).to eq(1)
    end

    it "prints error and returns 1 for an invalid state" do
      exit_code = described_class.run(["invalid"], stdout: stdout, stderr: stderr, api_client: api_client)

      expect(stderr.string).to include("state must be one of")
      expect(exit_code).to eq(1)
    end

    it "prints error when warning is given without --severity" do
      exit_code = described_class.run(["warning"], stdout: stdout, stderr: stderr, api_client: api_client)

      expect(stderr.string).to include("--severity is required")
      expect(exit_code).to eq(1)
    end

    it "prints error when --severity is given with a non-warning state" do
      exit_code = described_class.run(["recording", "--severity", "high"],
        stdout: stdout, stderr: stderr, api_client: api_client)

      expect(stderr.string).to include("--severity is only valid")
      expect(exit_code).to eq(1)
    end
  end

  it_behaves_like "command error handling",
    api_method: :set_display_state,
    run_args: ["recording"],
    include_parse_error: false
end
