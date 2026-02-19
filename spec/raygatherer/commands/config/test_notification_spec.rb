# frozen_string_literal: true

RSpec.describe Raygatherer::Commands::Config::TestNotification do
  describe ".run" do
    include_context "command context"

    it_behaves_like "a command with help", "config test-notification"

    describe "sending test notification" do
      it "sends test notification and prints success" do
        allow(api_client).to receive(:test_notification)

        exit_code = described_class.run([], stdout: stdout, stderr: stderr, api_client: api_client)

        expect(api_client).to have_received(:test_notification)
        expect(stdout.string).to include("Test notification sent")
        expect(exit_code).to eq(0)
      end
    end

    it_behaves_like "command error handling",
      api_method: :test_notification, include_parse_error: false
  end
end
