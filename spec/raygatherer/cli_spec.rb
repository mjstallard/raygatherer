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
  end
end
