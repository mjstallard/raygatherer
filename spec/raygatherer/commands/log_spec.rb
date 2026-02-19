# frozen_string_literal: true

RSpec.describe Raygatherer::Commands::Log do
  describe ".run" do
    include_context "command context"

    it_behaves_like "a command with help", "log"

    describe "fetching and printing the log" do
      let(:log_content) { "2024-01-01T00:00:00Z INFO Starting rayhunter\n2024-01-01T00:00:01Z DEBUG Ready\n" }

      it "prints the log exactly as returned" do
        allow(api_client).to receive(:fetch_log).and_return(log_content)

        exit_code = described_class.run([], stdout: stdout, stderr: stderr, api_client: api_client)

        expect(stdout.string).to eq(log_content)
        expect(exit_code).to eq(0)
      end
    end

    it_behaves_like "command error handling", api_method: :fetch_log, include_parse_error: false
  end
end
