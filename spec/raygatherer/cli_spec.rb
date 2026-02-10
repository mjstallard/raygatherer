# frozen_string_literal: true

RSpec.describe Raygatherer::CLI do
  describe ".run" do
    let(:stdout) { StringIO.new }
    let(:stderr) { StringIO.new }

    describe "--version flag" do
      it "outputs the version" do
        exit_code = described_class.run(["--version"], stdout: stdout, stderr: stderr)

        expect(stdout.string).to include("raygatherer version #{Raygatherer::VERSION}")
        expect(exit_code).to eq(0)
      end

      it "uses short form -v" do
        exit_code = described_class.run(["-v"], stdout: stdout, stderr: stderr)

        expect(stdout.string).to include("raygatherer version #{Raygatherer::VERSION}")
        expect(exit_code).to eq(0)
      end
    end

    describe "--help flag" do
      it "shows usage information" do
        exit_code = described_class.run(["--help"], stdout: stdout, stderr: stderr)

        expect(stdout.string).to include("Usage:")
        expect(stdout.string).to include("--version")
        expect(stdout.string).to include("--help")
        expect(exit_code).to eq(0)
      end

      it "uses short form -h" do
        exit_code = described_class.run(["-h"], stdout: stdout, stderr: stderr)

        expect(stdout.string).to include("Usage:")
        expect(exit_code).to eq(0)
      end
    end

    describe "with no arguments" do
      it "shows help message" do
        exit_code = described_class.run([], stdout: stdout, stderr: stderr)

        expect(stdout.string).to include("Usage:")
        expect(exit_code).to eq(0)
      end
    end

    describe "with invalid flag" do
      it "shows error message" do
        exit_code = described_class.run(["--invalid"], stdout: stdout, stderr: stderr)

        expect(stderr.string).to include("invalid option")
        expect(exit_code).to eq(1)
      end

      it "shows help after error" do
        exit_code = described_class.run(["--invalid"], stdout: stdout, stderr: stderr)

        expect(stderr.string).to include("Usage:")
        expect(exit_code).to eq(1)
      end
    end

    describe "command routing" do
      it "routes 'alert status' to Commands::Alert::Status" do
        allow(Raygatherer::Commands::Alert::Status).to receive(:run).and_return(0)

        exit_code = described_class.run(["alert", "status", "--host", "http://test"], stdout: stdout, stderr: stderr)

        expect(Raygatherer::Commands::Alert::Status).to have_received(:run).with(
          ["--host", "http://test"],
          stdout: stdout,
          stderr: stderr,
          verbose: false
        )
        expect(exit_code).to eq(0)
      end

      it "passes remaining argv to command" do
        allow(Raygatherer::Commands::Alert::Status).to receive(:run).and_return(0)

        described_class.run(["alert", "status", "--host", "http://test", "--json"], stdout: stdout, stderr: stderr)

        expect(Raygatherer::Commands::Alert::Status).to have_received(:run).with(
          ["--host", "http://test", "--json"],
          stdout: stdout,
          stderr: stderr,
          verbose: false
        )
      end

      it "returns command exit code" do
        allow(Raygatherer::Commands::Alert::Status).to receive(:run).and_return(42)

        exit_code = described_class.run(["alert", "status", "--host", "http://test"], stdout: stdout, stderr: stderr)

        expect(exit_code).to eq(42)
      end

      it "shows error for unknown command" do
        exit_code = described_class.run(["unknown"], stdout: stdout, stderr: stderr)

        expect(stderr.string).to include("Unknown command")
        expect(stderr.string).to include("unknown")
        expect(exit_code).to eq(1)
      end

      it "shows error for unknown subcommand" do
        exit_code = described_class.run(["alert", "unknown"], stdout: stdout, stderr: stderr)

        expect(stderr.string).to include("Unknown command")
        expect(stderr.string).to include("alert unknown")
        expect(exit_code).to eq(1)
      end

      it "shows help after unknown command error" do
        exit_code = described_class.run(["unknown"], stdout: stdout, stderr: stderr)

        expect(stderr.string).to include("Usage:")
        expect(exit_code).to eq(1)
      end
    end

    describe "--verbose flag" do
      it "extracts --verbose before command routing" do
        allow(Raygatherer::Commands::Alert::Status).to receive(:run).and_return(0)

        described_class.run(["--verbose", "alert", "status", "--host", "http://test"],
                            stdout: stdout, stderr: stderr)

        expect(Raygatherer::Commands::Alert::Status).to have_received(:run).with(
          ["--host", "http://test"],
          stdout: stdout,
          stderr: stderr,
          verbose: true
        )
      end

      it "passes verbose: false when flag not present" do
        allow(Raygatherer::Commands::Alert::Status).to receive(:run).and_return(0)

        described_class.run(["alert", "status", "--host", "http://test"],
                            stdout: stdout, stderr: stderr)

        expect(Raygatherer::Commands::Alert::Status).to have_received(:run).with(
          ["--host", "http://test"],
          stdout: stdout,
          stderr: stderr,
          verbose: false
        )
      end

      it "works with --verbose anywhere in global position" do
        allow(Raygatherer::Commands::Alert::Status).to receive(:run).and_return(0)

        described_class.run(["alert", "status", "--verbose", "--host", "http://test"],
                            stdout: stdout, stderr: stderr)

        # --verbose should be extracted, not passed to command
        expect(Raygatherer::Commands::Alert::Status).to have_received(:run).with(
          ["--host", "http://test"],
          stdout: stdout,
          stderr: stderr,
          verbose: true
        )
      end

      it "shows help when only --verbose is provided" do
        exit_code = described_class.run(["--verbose"], stdout: stdout, stderr: stderr)

        expect(stdout.string).to include("Usage:")
        expect(exit_code).to eq(0)
      end
    end
  end
end
