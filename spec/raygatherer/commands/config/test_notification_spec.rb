# frozen_string_literal: true

RSpec.describe Raygatherer::Commands::Config::TestNotification do
  describe ".run" do
    let(:stdout) { StringIO.new }
    let(:stderr) { StringIO.new }
    let(:api_client) { instance_double(Raygatherer::ApiClient) }

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

    describe "error handling" do
      it "handles connection errors gracefully" do
        allow(api_client).to receive(:test_notification).and_raise(
          Raygatherer::ApiClient::ConnectionError, "Connection failed"
        )

        exit_code = described_class.run([], stdout: stdout, stderr: stderr, api_client: api_client)

        expect(stderr.string).to include("Error: Connection failed")
        expect(exit_code).to eq(1)
      end

      it "handles API errors gracefully (e.g. no URL configured)" do
        allow(api_client).to receive(:test_notification).and_raise(
          Raygatherer::ApiClient::ApiError, "Server returned 400: No notification URL configured"
        )

        exit_code = described_class.run([], stdout: stdout, stderr: stderr, api_client: api_client)

        expect(stderr.string).to include("Error: Server returned 400: No notification URL configured")
        expect(exit_code).to eq(1)
      end
    end
  end
end
