# frozen_string_literal: true

RSpec.shared_examples "a subcommand" do |args:, command_name:, help_includes: []|
  describe "raygatherer #{command_name}" do
    it "requires --host flag" do
      _, stderr, status = Open3.capture3(@clean_env, exe_path, *args)

      expect(stderr).to include("--host is required")
      expect(stderr).to include("Usage:")
      expect(status.exitstatus).to eq(1)
    end

    it "shows help with --help" do
      stdout, stderr, status = Open3.capture3(@clean_env, exe_path, *args, "--help")

      expect(stdout).to include("Usage:")
      expect(stdout).to include(command_name)
      expect(stdout).to include("--host")
      help_includes.each { |text| expect(stdout).to include(text) }
      expect(strip_ruby_warnings(stderr)).to be_empty
      expect(status.exitstatus).to eq(0)
    end

    it "handles connection errors gracefully" do
      _, stderr, status = Open3.capture3(@clean_env, exe_path, *args, "--host", "http://localhost:9999")

      expect(stderr).to include("Error")
      expect(stderr).to include("Failed to connect")
      expect(status.exitstatus).to eq(1)
    end
  end
end

RSpec.shared_examples "visible in main help" do |command_name|
  it "shows #{command_name} in main help output" do
    stdout, _, status = Open3.capture3(@clean_env, exe_path, "--help")

    expect(stdout).to include(command_name)
    expect(status.exitstatus).to eq(0)
  end
end
