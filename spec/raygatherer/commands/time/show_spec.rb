# frozen_string_literal: true

RSpec.describe Raygatherer::Commands::Time::Show do
  describe ".run" do
    include_context "command context"
    let(:time_data) do
      {
        "system_time" => "2024-12-15T10:30:45-08:00",
        "adjusted_time" => "2024-12-15T10:30:50-08:00",
        "offset_seconds" => 5
      }
    end

    it_behaves_like "a command with help", "time show"

    it "outputs human format by default" do
      allow(api_client).to receive(:fetch_time).and_return(time_data)

      exit_code = described_class.run([], stdout: stdout, stderr: stderr, api_client: api_client)

      expect(stdout.string).to include("System time:   2024-12-15T10:30:45-08:00")
      expect(stdout.string).to include("Adjusted time: 2024-12-15T10:30:50-08:00")
      expect(stdout.string).to include("Offset:        5s")
      expect(exit_code).to eq(0)
    end

    it "outputs JSON when json: true" do
      allow(api_client).to receive(:fetch_time).and_return(time_data)

      exit_code = described_class.run([], stdout: stdout, stderr: stderr, api_client: api_client, json: true)

      parsed = ::JSON.parse(stdout.string.strip)
      expect(parsed["system_time"]).to eq("2024-12-15T10:30:45-08:00")
      expect(parsed["offset_seconds"]).to eq(5)
      expect(exit_code).to eq(0)
    end

    it_behaves_like "command error handling", api_method: :fetch_time
  end
end
