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
        api_client = instance_double(Raygatherer::ApiClient)
        allow(Raygatherer::ApiClient).to receive(:new).and_return(api_client)
        allow(Raygatherer::Commands::Alert::Status).to receive(:run).and_return(0)

        exit_code = described_class.run(["alert", "status", "--host", "http://test"], stdout: stdout, stderr: stderr)

        expect(Raygatherer::ApiClient).to have_received(:new).with(
          "http://test", username: nil, password: nil, verbose: false, stderr: stderr
        )
        expect(Raygatherer::Commands::Alert::Status).to have_received(:run).with(
          [],
          stdout: stdout,
          stderr: stderr,
          api_client: api_client,
          json: false
        )
        expect(exit_code).to eq(0)
      end

      it "passes --json as keyword param to command" do
        api_client = instance_double(Raygatherer::ApiClient)
        allow(Raygatherer::ApiClient).to receive(:new).and_return(api_client)
        allow(Raygatherer::Commands::Alert::Status).to receive(:run).and_return(0)

        described_class.run(["alert", "status", "--host", "http://test", "--json"], stdout: stdout, stderr: stderr)

        expect(Raygatherer::Commands::Alert::Status).to have_received(:run).with(
          [],
          stdout: stdout,
          stderr: stderr,
          api_client: api_client,
          json: true
        )
      end

      it "returns command exit code" do
        api_client = instance_double(Raygatherer::ApiClient)
        allow(Raygatherer::ApiClient).to receive(:new).and_return(api_client)
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

      it "routes 'recording list' to Commands::Recording::List" do
        api_client = instance_double(Raygatherer::ApiClient)
        allow(Raygatherer::ApiClient).to receive(:new).and_return(api_client)
        allow(Raygatherer::Commands::Recording::List).to receive(:run).and_return(0)

        exit_code = described_class.run(["recording", "list", "--host", "http://test"], stdout: stdout, stderr: stderr)

        expect(Raygatherer::ApiClient).to have_received(:new).with(
          "http://test", username: nil, password: nil, verbose: false, stderr: stderr
        )
        expect(Raygatherer::Commands::Recording::List).to have_received(:run).with(
          [],
          stdout: stdout,
          stderr: stderr,
          api_client: api_client,
          json: false
        )
        expect(exit_code).to eq(0)
      end

      it "passes --verbose to recording list command" do
        api_client = instance_double(Raygatherer::ApiClient)
        allow(Raygatherer::ApiClient).to receive(:new).and_return(api_client)
        allow(Raygatherer::Commands::Recording::List).to receive(:run).and_return(0)

        described_class.run(["--verbose", "recording", "list", "--host", "http://test"],
                            stdout: stdout, stderr: stderr)

        expect(Raygatherer::ApiClient).to have_received(:new).with(
          "http://test", username: nil, password: nil, verbose: true, stderr: stderr
        )
        expect(Raygatherer::Commands::Recording::List).to have_received(:run).with(
          [],
          stdout: stdout,
          stderr: stderr,
          api_client: api_client,
          json: false
        )
      end

      it "routes 'recording download' to Commands::Recording::Download" do
        api_client = instance_double(Raygatherer::ApiClient)
        allow(Raygatherer::ApiClient).to receive(:new).and_return(api_client)
        allow(Raygatherer::Commands::Recording::Download).to receive(:run).and_return(0)

        exit_code = described_class.run(
          ["recording", "download", "myrecording", "--host", "http://test"],
          stdout: stdout, stderr: stderr
        )

        expect(Raygatherer::Commands::Recording::Download).to have_received(:run).with(
          ["myrecording"],
          stdout: stdout,
          stderr: stderr,
          api_client: api_client
        )
        expect(exit_code).to eq(0)
      end

      it "routes 'recording delete' to Commands::Recording::Delete" do
        api_client = instance_double(Raygatherer::ApiClient)
        allow(Raygatherer::ApiClient).to receive(:new).and_return(api_client)
        allow(Raygatherer::Commands::Recording::Delete).to receive(:run).and_return(0)

        exit_code = described_class.run(
          ["recording", "delete", "myrecording", "--host", "http://test"],
          stdout: stdout, stderr: stderr
        )

        expect(Raygatherer::Commands::Recording::Delete).to have_received(:run).with(
          ["myrecording"],
          stdout: stdout,
          stderr: stderr,
          api_client: api_client
        )
        expect(exit_code).to eq(0)
      end

      it "routes 'recording stop' to Commands::Recording::Stop" do
        api_client = instance_double(Raygatherer::ApiClient)
        allow(Raygatherer::ApiClient).to receive(:new).and_return(api_client)
        allow(Raygatherer::Commands::Recording::Stop).to receive(:run).and_return(0)

        exit_code = described_class.run(
          ["recording", "stop", "--host", "http://test"],
          stdout: stdout, stderr: stderr
        )

        expect(Raygatherer::Commands::Recording::Stop).to have_received(:run).with(
          [],
          stdout: stdout,
          stderr: stderr,
          api_client: api_client
        )
        expect(exit_code).to eq(0)
      end

      it "routes 'recording start' to Commands::Recording::Start" do
        api_client = instance_double(Raygatherer::ApiClient)
        allow(Raygatherer::ApiClient).to receive(:new).and_return(api_client)
        allow(Raygatherer::Commands::Recording::Start).to receive(:run).and_return(0)

        exit_code = described_class.run(
          ["recording", "start", "--host", "http://test"],
          stdout: stdout, stderr: stderr
        )

        expect(Raygatherer::Commands::Recording::Start).to have_received(:run).with(
          [],
          stdout: stdout,
          stderr: stderr,
          api_client: api_client
        )
        expect(exit_code).to eq(0)
      end

      it "routes 'stats' to Commands::Stats" do
        api_client = instance_double(Raygatherer::ApiClient)
        allow(Raygatherer::ApiClient).to receive(:new).and_return(api_client)
        allow(Raygatherer::Commands::Stats).to receive(:run).and_return(0)

        exit_code = described_class.run(["stats", "--host", "http://test"], stdout: stdout, stderr: stderr)

        expect(Raygatherer::ApiClient).to have_received(:new).with(
          "http://test", username: nil, password: nil, verbose: false, stderr: stderr
        )
        expect(Raygatherer::Commands::Stats).to have_received(:run).with(
          [],
          stdout: stdout,
          stderr: stderr,
          api_client: api_client,
          json: false
        )
        expect(exit_code).to eq(0)
      end

      it "passes --json to stats command" do
        api_client = instance_double(Raygatherer::ApiClient)
        allow(Raygatherer::ApiClient).to receive(:new).and_return(api_client)
        allow(Raygatherer::Commands::Stats).to receive(:run).and_return(0)

        described_class.run(["--json", "stats", "--host", "http://test"], stdout: stdout, stderr: stderr)

        expect(Raygatherer::Commands::Stats).to have_received(:run).with(
          [],
          stdout: stdout,
          stderr: stderr,
          api_client: api_client,
          json: true
        )
      end

      it "passes --verbose to stats command" do
        api_client = instance_double(Raygatherer::ApiClient)
        allow(Raygatherer::ApiClient).to receive(:new).and_return(api_client)
        allow(Raygatherer::Commands::Stats).to receive(:run).and_return(0)

        described_class.run(["--verbose", "stats", "--host", "http://test"], stdout: stdout, stderr: stderr)

        expect(Raygatherer::ApiClient).to have_received(:new).with(
          "http://test", username: nil, password: nil, verbose: true, stderr: stderr
        )
        expect(Raygatherer::Commands::Stats).to have_received(:run).with(
          [],
          stdout: stdout,
          stderr: stderr,
          api_client: api_client,
          json: false
        )
      end
    end

    describe "--verbose flag" do
      it "extracts --verbose before command routing" do
        api_client = instance_double(Raygatherer::ApiClient)
        allow(Raygatherer::ApiClient).to receive(:new).and_return(api_client)
        allow(Raygatherer::Commands::Alert::Status).to receive(:run).and_return(0)

        described_class.run(["--verbose", "alert", "status", "--host", "http://test"],
                            stdout: stdout, stderr: stderr)

        expect(Raygatherer::ApiClient).to have_received(:new).with(
          "http://test", username: nil, password: nil, verbose: true, stderr: stderr
        )
        expect(Raygatherer::Commands::Alert::Status).to have_received(:run).with(
          [],
          stdout: stdout,
          stderr: stderr,
          api_client: api_client,
          json: false
        )
      end

      it "passes verbose: false when flag not present" do
        api_client = instance_double(Raygatherer::ApiClient)
        allow(Raygatherer::ApiClient).to receive(:new).and_return(api_client)
        allow(Raygatherer::Commands::Alert::Status).to receive(:run).and_return(0)

        described_class.run(["alert", "status", "--host", "http://test"],
                            stdout: stdout, stderr: stderr)

        expect(Raygatherer::ApiClient).to have_received(:new).with(
          "http://test", username: nil, password: nil, verbose: false, stderr: stderr
        )
      end

      it "works with --verbose anywhere in global position" do
        api_client = instance_double(Raygatherer::ApiClient)
        allow(Raygatherer::ApiClient).to receive(:new).and_return(api_client)
        allow(Raygatherer::Commands::Alert::Status).to receive(:run).and_return(0)

        described_class.run(["alert", "status", "--verbose", "--host", "http://test"],
                            stdout: stdout, stderr: stderr)

        # --verbose should be extracted and passed to ApiClient, not to command
        expect(Raygatherer::ApiClient).to have_received(:new).with(
          "http://test", username: nil, password: nil, verbose: true, stderr: stderr
        )
        expect(Raygatherer::Commands::Alert::Status).to have_received(:run).with(
          [],
          stdout: stdout,
          stderr: stderr,
          api_client: api_client,
          json: false
        )
      end

      it "shows help when only --verbose is provided" do
        exit_code = described_class.run(["--verbose"], stdout: stdout, stderr: stderr)

        expect(stdout.string).to include("Usage:")
        expect(exit_code).to eq(0)
      end
    end

    describe "global flag extraction" do
      it "extracts --host and passes to ApiClient" do
        api_client = instance_double(Raygatherer::ApiClient)
        allow(Raygatherer::ApiClient).to receive(:new).and_return(api_client)
        allow(Raygatherer::Commands::Alert::Status).to receive(:run).and_return(0)

        described_class.run(["--host", "http://myhost", "alert", "status"],
                            stdout: stdout, stderr: stderr)

        expect(Raygatherer::ApiClient).to have_received(:new).with(
          "http://myhost", username: nil, password: nil, verbose: false, stderr: stderr
        )
        expect(Raygatherer::Commands::Alert::Status).to have_received(:run).with(
          [],
          stdout: stdout,
          stderr: stderr,
          api_client: api_client,
          json: false
        )
      end

      it "extracts --basic-auth-user and --basic-auth-password" do
        api_client = instance_double(Raygatherer::ApiClient)
        allow(Raygatherer::ApiClient).to receive(:new).and_return(api_client)
        allow(Raygatherer::Commands::Alert::Status).to receive(:run).and_return(0)

        described_class.run([
          "alert", "status",
          "--host", "http://test",
          "--basic-auth-user", "admin",
          "--basic-auth-password", "secret"
        ], stdout: stdout, stderr: stderr)

        expect(Raygatherer::ApiClient).to have_received(:new).with(
          "http://test", username: "admin", password: "secret", verbose: false, stderr: stderr
        )
      end

      it "extracts --json and passes as keyword param" do
        api_client = instance_double(Raygatherer::ApiClient)
        allow(Raygatherer::ApiClient).to receive(:new).and_return(api_client)
        allow(Raygatherer::Commands::Recording::List).to receive(:run).and_return(0)

        described_class.run(["--json", "recording", "list", "--host", "http://test"],
                            stdout: stdout, stderr: stderr)

        expect(Raygatherer::Commands::Recording::List).to have_received(:run).with(
          [],
          stdout: stdout,
          stderr: stderr,
          api_client: api_client,
          json: true
        )
      end

      it "extracts all global flags together" do
        api_client = instance_double(Raygatherer::ApiClient)
        allow(Raygatherer::ApiClient).to receive(:new).and_return(api_client)
        allow(Raygatherer::Commands::Alert::Status).to receive(:run).and_return(0)

        described_class.run([
          "--verbose",
          "--host", "http://myhost",
          "--basic-auth-user", "user1",
          "--basic-auth-password", "pass1",
          "--json",
          "alert", "status"
        ], stdout: stdout, stderr: stderr)

        expect(Raygatherer::ApiClient).to have_received(:new).with(
          "http://myhost", username: "user1", password: "pass1", verbose: true, stderr: stderr
        )
        expect(Raygatherer::Commands::Alert::Status).to have_received(:run).with(
          [],
          stdout: stdout,
          stderr: stderr,
          api_client: api_client,
          json: true
        )
      end
    end
  end
end
