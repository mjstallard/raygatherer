# frozen_string_literal: true

RSpec.describe Raygatherer::Commands::Gps::Set do
  describe ".run" do
    include_context "command context"

    it_behaves_like "a command with help", "gps set"

    it "submits the given latitude and longitude and prints confirmation" do
      allow(api_client).to receive(:set_gps)

      exit_code = described_class.run(["51.5", "-0.1"], stdout: stdout, stderr: stderr, api_client: api_client)

      expect(api_client).to have_received(:set_gps).with(51.5, -0.1)
      expect(stdout.string).to include("GPS position set: 51.5, -0.1")
      expect(exit_code).to eq(0)
    end

    it "shows help even when a negative-looking coordinate precedes --help" do
      expect do
        described_class.run(["51.5074", "-0.1278", "--help"], stdout: stdout, stderr: stderr)
      end.to raise_error(Raygatherer::CLI::EarlyExit) do |error|
        expect(error.exit_code).to eq(0)
        expect(stdout.string).to include("Usage:")
      end
    end

    it "prints an error and returns 1 when arguments are missing" do
      exit_code = described_class.run(["51.5"], stdout: stdout, stderr: stderr, api_client: api_client)

      expect(stderr.string).to include("latitude and longitude are required")
      expect(exit_code).to eq(1)
    end

    it "prints an error and returns 1 when latitude is not numeric" do
      exit_code = described_class.run(["abc", "-0.1"], stdout: stdout, stderr: stderr, api_client: api_client)

      expect(stderr.string).to include("latitude must be a number")
      expect(exit_code).to eq(1)
    end

    it "prints an error and returns 1 when longitude is not numeric" do
      exit_code = described_class.run(["51.5", "abc"], stdout: stdout, stderr: stderr, api_client: api_client)

      expect(stderr.string).to include("longitude must be a number")
      expect(exit_code).to eq(1)
    end

    it_behaves_like "command error handling",
      api_method: :set_gps,
      run_args: ["51.5", "-0.1"],
      include_parse_error: false
  end
end
