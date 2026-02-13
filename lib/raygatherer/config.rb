# frozen_string_literal: true

require "yaml"

module Raygatherer
  class Config
    class ConfigError < StandardError; end

    SUPPORTED_KEYS = %w[host basic_auth_user basic_auth_password json verbose].freeze

    def initialize(config_path: nil, env: ENV)
      @config_path = config_path || default_config_path(env)
    end

    def load
      return {} unless File.exist?(@config_path)

      content = File.read(@config_path)
      return {} if content.strip.empty?

      parsed = YAML.safe_load(content)

      unless parsed.is_a?(Hash)
        raise ConfigError, "Config file must be a YAML mapping (key: value), got #{parsed.class}"
      end

      parsed.select { |key, _| SUPPORTED_KEYS.include?(key) }
    rescue Psych::SyntaxError => e
      raise ConfigError, "Could not parse config file #{@config_path}: #{e.message}"
    end

    private

    def default_config_path(env)
      xdg_home = env["XDG_CONFIG_HOME"]
      base = xdg_home && !xdg_home.empty? ? xdg_home : File.join(Dir.home, ".config")
      File.join(base, "raygatherer", "config.yml")
    end
  end
end
