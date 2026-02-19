# frozen_string_literal: true

RSpec.describe Raygatherer::Commands::Stats do
  describe ".run" do
    include_context "command context"

    it_behaves_like "a command with help", "stats"

    describe "fetching and displaying stats" do
      let(:stats) do
        {
          "disk_stats" => {"total_size" => "128G", "used_size" => "64G",
                           "used_percent" => "50%", "mounted_on" => "/data"},
          "memory_stats" => {"total" => "28.3M", "used" => "15.1M", "free" => "13.2M"},
          "runtime_metadata" => {"rayhunter_version" => "1.2.3", "system_os" => "Linux 3.18.48", "arch" => "armv7l"}
        }
      end

      it "outputs human format by default" do
        allow(api_client).to receive(:fetch_system_stats).and_return(stats)

        exit_code = described_class.run([], stdout: stdout, stderr: stderr, api_client: api_client)

        expect(stdout.string).to include("Rayhunter v1.2.3")
        expect(stdout.string).to include("Disk:")
        expect(exit_code).to eq(0)
      end

      it "outputs JSON when json: true" do
        allow(api_client).to receive(:fetch_system_stats).and_return(stats)

        exit_code = described_class.run([], stdout: stdout, stderr: stderr, api_client: api_client, json: true)

        parsed = ::JSON.parse(stdout.string.strip)
        expect(parsed["disk_stats"]["total_size"]).to eq("128G")
        expect(exit_code).to eq(0)
      end
    end

    it_behaves_like "command error handling", api_method: :fetch_system_stats
  end
end
