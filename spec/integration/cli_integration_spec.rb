# frozen_string_literal: true

require "open3"

RSpec.describe "CLI Integration" do
  let(:exe_path) { File.expand_path("../../exe/raygatherer", __dir__) }

  describe "raygatherer --version" do
    it "outputs version and exits successfully" do
      stdout, stderr, status = Open3.capture3(exe_path, "--version")

      expect(stdout).to include("raygatherer version")
      expect(stdout).to include(Raygatherer::VERSION)
      expect(stderr).to be_empty
      expect(status.exitstatus).to eq(0)
    end
  end

  describe "raygatherer --help" do
    it "outputs help and exits successfully" do
      stdout, stderr, status = Open3.capture3(exe_path, "--help")

      expect(stdout).to include("Usage:")
      expect(stdout).to include("--version")
      expect(stdout).to include("--help")
      expect(stderr).to be_empty
      expect(status.exitstatus).to eq(0)
    end
  end

  describe "raygatherer with no args" do
    it "outputs help and exits successfully" do
      stdout, stderr, status = Open3.capture3(exe_path)

      expect(stdout).to include("Usage:")
      expect(stderr).to be_empty
      expect(status.exitstatus).to eq(0)
    end
  end

  describe "raygatherer with invalid flag" do
    it "outputs error to stderr and exits with failure" do
      stdout, stderr, status = Open3.capture3(exe_path, "--invalid")

      expect(stderr).to include("invalid option")
      expect(stderr).to include("Usage:")
      expect(status.exitstatus).to eq(1)
    end
  end
end
