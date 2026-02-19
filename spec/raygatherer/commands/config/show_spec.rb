# frozen_string_literal: true

RSpec.describe Raygatherer::Commands::Config::Show do
  describe ".run" do
    include_context "command context"

    let(:config_data) do
      {
        "qmdl_store_path" => "/data/rayhunter",
        "port" => 8080,
        "readonly_port" => 8081,
        "notification_url" => nil,
        "analyzers" => {
          "null_cipher" => true,
          "imsi_catcher" => true
        }
      }
    end

    it_behaves_like "a command with help", "config show"

    describe "fetching and displaying config" do
      it "outputs human format by default" do
        allow(api_client).to receive(:fetch_config).and_return(config_data)

        exit_code = described_class.run([], stdout: stdout, stderr: stderr, api_client: api_client)

        expect(stdout.string).to include("Port: 8080")
        expect(stdout.string).to include("Analyzers:")
        expect(exit_code).to eq(0)
      end

      it "outputs JSON when json: true" do
        allow(api_client).to receive(:fetch_config).and_return(config_data)

        exit_code = described_class.run([], stdout: stdout, stderr: stderr, api_client: api_client, json: true)

        parsed = ::JSON.parse(stdout.string.strip)
        expect(parsed["port"]).to eq(8080)
        expect(exit_code).to eq(0)
      end
    end

    it_behaves_like "command error handling",
      api_method: :fetch_config, include_parse_error: false
  end
end
