# frozen_string_literal: true

require "time"

RSpec.describe Raygatherer::Commands::Time::Sync do
  describe ".run" do
    let(:stdout) { StringIO.new }
    let(:stderr) { StringIO.new }
    let(:api_client) { instance_double(Raygatherer::ApiClient) }
    let(:time_data) do
      {
        "system_time" => "2024-12-15T10:30:45-08:00",
        "adjusted_time" => "2024-12-15T10:30:50-08:00",
        "offset_seconds" => 5
      }
    end

    it_behaves_like "a command with help", "time sync"

    it "computes offset and calls set_time_offset" do
      device_time = ::Time.parse("2024-12-15T10:30:45-08:00")
      local_time = device_time + 7

      allow(api_client).to receive(:fetch_time).and_return(time_data)
      allow(api_client).to receive(:set_time_offset)
      allow(::Time).to receive(:now).and_return(local_time)

      described_class.run([], stdout: stdout, stderr: stderr, api_client: api_client)

      expect(api_client).to have_received(:set_time_offset).with(7)
    end

    it "prints sync confirmation with offset" do
      device_time = ::Time.parse("2024-12-15T10:30:45-08:00")
      local_time = device_time + 7

      allow(api_client).to receive(:fetch_time).and_return(time_data)
      allow(api_client).to receive(:set_time_offset)
      allow(::Time).to receive(:now).and_return(local_time)

      exit_code = described_class.run([], stdout: stdout, stderr: stderr, api_client: api_client)

      expect(stdout.string).to include("Clock synced. Offset: 7s")
      expect(exit_code).to eq(0)
    end

    it_behaves_like "command error handling", api_method: :fetch_time, include_parse_error: false
  end
end
