# frozen_string_literal: true

RSpec.shared_examples "command error handling" do |api_method:, run_args: [], include_parse_error: true|
  describe "error handling" do
    it "handles connection errors gracefully" do
      allow(api_client).to receive(api_method).and_raise(
        Raygatherer::ApiClient::ConnectionError, "Connection failed"
      )

      exit_code = described_class.run(run_args.dup, stdout: stdout, stderr: stderr, api_client: api_client)

      expect(stderr.string).to include("Error: Connection failed")
      expect(exit_code).to eq(1)
    end

    it "handles API errors gracefully" do
      allow(api_client).to receive(api_method).and_raise(
        Raygatherer::ApiClient::ApiError, "Server error"
      )

      exit_code = described_class.run(run_args.dup, stdout: stdout, stderr: stderr, api_client: api_client)

      expect(stderr.string).to include("Error: Server error")
      expect(exit_code).to eq(1)
    end

    if include_parse_error
      it "handles parse errors gracefully" do
        allow(api_client).to receive(api_method).and_raise(
          Raygatherer::ApiClient::ParseError, "Invalid JSON"
        )

        exit_code = described_class.run(run_args.dup, stdout: stdout, stderr: stderr, api_client: api_client)

        expect(stderr.string).to include("Error: Invalid JSON")
        expect(exit_code).to eq(1)
      end
    end
  end
end
