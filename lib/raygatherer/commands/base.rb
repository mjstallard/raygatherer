# frozen_string_literal: true

module Raygatherer
  module Commands
    EXIT_CODE_SUCCESS = 0
    EXIT_CODE_ERROR = 1

    class Base
      def self.run(argv, **kwargs)
        new(argv, **kwargs).run
      end

      def initialize(argv, stdout: $stdout, stderr: $stderr, api_client: nil, **_kwargs)
        @argv = argv
        @stdout = stdout
        @stderr = stderr
        @api_client = api_client
      end

      private

      def print_global_options(output, json: false)
        output.puts "Global options (see 'raygatherer --help'):"
        if json
          output.puts "    --host, --basic-auth-user, --basic-auth-password, --json, --verbose"
        else
          output.puts "    --host, --basic-auth-user, --basic-auth-password, --verbose"
        end
      end

      def with_error_handling
        yield
      rescue CLI::EarlyExit
        raise
      rescue => e
        @stderr.puts "Error: #{e.message}"
        EXIT_CODE_ERROR
      end

      def warn_if_rayhunter_outdated(rayhunter_version)
        actual = Gem::Version.new(rayhunter_version)
        tested = Gem::Version.new(Raygatherer::TESTED_RAYHUNTER_VERSION)
        return unless actual < tested

        @stderr.puts "Warning: connected rayhunter is v#{rayhunter_version}; raygatherer was last " \
          "tested against v#{Raygatherer::TESTED_RAYHUNTER_VERSION} — some fields or commands may not be supported."
      rescue ArgumentError
        nil
      end
    end
  end
end
