# frozen_string_literal: true

RSpec.shared_examples "a command with help" do |command_name|
  describe "--help flag" do
    it "shows help with --help" do
      expect do
        described_class.run(["--help"], stdout: stdout, stderr: stderr)
      end.to raise_error(Raygatherer::CLI::EarlyExit) do |error|
        expect(error.exit_code).to eq(0)
        expect(stdout.string).to include("Usage:")
        expect(stdout.string).to include(command_name)
      end
    end

    it "shows help with -h" do
      expect do
        described_class.run(["-h"], stdout: stdout, stderr: stderr)
      end.to raise_error(Raygatherer::CLI::EarlyExit) do |error|
        expect(error.exit_code).to eq(0)
      end
    end
  end
end
