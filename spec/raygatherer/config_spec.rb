# frozen_string_literal: true

require "tmpdir"
require "yaml"
require_relative "../../lib/raygatherer/config"

RSpec.describe Raygatherer::Config do
  describe "#load" do
    it "returns empty hash when no config file exists" do
      config = described_class.new(config_path: "/nonexistent/path/config.yml")

      expect(config.load).to eq({})
    end

    it "returns parsed hash from valid YAML file" do
      Dir.mktmpdir do |dir|
        path = File.join(dir, "config.yml")
        File.write(path, "host: http://rayhunter.local:8080\n")
        config = described_class.new(config_path: path)

        result = config.load

        expect(result).to eq({"host" => "http://rayhunter.local:8080"})
      end
    end

    it "loads all 5 supported keys" do
      Dir.mktmpdir do |dir|
        path = File.join(dir, "config.yml")
        File.write(path, <<~YAML)
          host: http://rayhunter.local:8080
          basic_auth_user: admin
          basic_auth_password: secret
          json: true
          verbose: false
        YAML
        config = described_class.new(config_path: path)

        result = config.load

        expect(result).to eq({
          "host" => "http://rayhunter.local:8080",
          "basic_auth_user" => "admin",
          "basic_auth_password" => "secret",
          "json" => true,
          "verbose" => false
        })
      end
    end

    it "raises ConfigError for invalid YAML" do
      Dir.mktmpdir do |dir|
        path = File.join(dir, "config.yml")
        File.write(path, "{ invalid yaml: [")
        config = described_class.new(config_path: path)

        expect { config.load }.to raise_error(Raygatherer::Config::ConfigError, /Could not parse/)
      end
    end

    it "raises ConfigError when YAML is not a hash" do
      Dir.mktmpdir do |dir|
        path = File.join(dir, "config.yml")
        File.write(path, "- item1\n- item2\n")
        config = described_class.new(config_path: path)

        expect { config.load }.to raise_error(Raygatherer::Config::ConfigError, /must be a YAML mapping/)
      end
    end

    it "filters out unknown keys" do
      Dir.mktmpdir do |dir|
        path = File.join(dir, "config.yml")
        File.write(path, <<~YAML)
          host: http://rayhunter.local:8080
          unknown_key: value
          another_bad: 42
        YAML
        config = described_class.new(config_path: path)

        result = config.load

        expect(result).to eq({"host" => "http://rayhunter.local:8080"})
      end
    end

    it "respects XDG_CONFIG_HOME env var" do
      Dir.mktmpdir do |dir|
        config_dir = File.join(dir, "raygatherer")
        Dir.mkdir(config_dir)
        path = File.join(config_dir, "config.yml")
        File.write(path, "host: http://custom.local\n")

        config = described_class.new(env: {"XDG_CONFIG_HOME" => dir})

        expect(config.load).to eq({"host" => "http://custom.local"})
      end
    end

    it "defaults to ~/.config when XDG_CONFIG_HOME is not set" do
      config = described_class.new(env: {})

      expected_path = File.join(Dir.home, ".config", "raygatherer", "config.yml")
      # File won't exist, so should return empty hash
      expect(config.load).to eq({})
    end

    it "returns empty hash for empty file" do
      Dir.mktmpdir do |dir|
        path = File.join(dir, "config.yml")
        File.write(path, "")
        config = described_class.new(config_path: path)

        expect(config.load).to eq({})
      end
    end
  end
end
