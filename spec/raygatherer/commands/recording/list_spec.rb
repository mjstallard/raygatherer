# frozen_string_literal: true

RSpec.describe Raygatherer::Commands::Recording::List do
  describe ".run" do
    let(:stdout) { StringIO.new }
    let(:stderr) { StringIO.new }
    let(:api_client) { instance_double(Raygatherer::ApiClient) }

    it_behaves_like "a command with help", "recording list"

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
            {"name" => "1738950000", "start_time" => "2025-02-07T13:40:00+00:00",
             "last_message_time" => "2025-02-07T15:30:00+00:00", "qmdl_size_bytes" => 134_963_200}
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
            {"name" => "1738950000", "start_time" => "2025-02-07T13:40:00+00:00",
             "last_message_time" => "2025-02-07T15:30:00+00:00", "qmdl_size_bytes" => 134_963_200}
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

    it_behaves_like "command error handling", api_method: :fetch_manifest
  end
end
