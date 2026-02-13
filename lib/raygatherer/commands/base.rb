# frozen_string_literal: true

module Raygatherer
  module Commands
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
        1
      end
    end
  end
end
