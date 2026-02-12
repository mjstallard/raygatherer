# frozen_string_literal: true

require "optparse"

module Raygatherer
  module Commands
    module Recording
      class Download
        EXTENSIONS = {
          qmdl: ".qmdl",
          pcap: ".pcap",
          zip: ".zip"
        }.freeze

        def self.run(argv, stdout: $stdout, stderr: $stderr, api_client: nil)
          new(argv, stdout: stdout, stderr: stderr, api_client: api_client).run
        end

        def initialize(argv, stdout: $stdout, stderr: $stderr, api_client: nil)
          @argv = argv
          @stdout = stdout
          @stderr = stderr
          @api_client = api_client
          @format = nil
          @format_flags = []
          @download_dir = nil
          @save_as = nil
        end

        def run
          parse_options
          return 1 unless validate_format_flags

          name = @argv.shift
          unless name
            @stderr.puts "Error: recording name is required"
            return 1
          end

          dest_path = resolve_destination(name)
          return 1 unless dest_path

          if File.exist?(dest_path)
            @stderr.puts "Error: file already exists: #{dest_path}"
            return 1
          end

          download_to_file(name, dest_path)

          size = File.size(dest_path)
          @stdout.puts "#{dest_path} (#{format_size(size)})"
          0
        rescue CLI::EarlyExit
          raise
        rescue ApiClient::ConnectionError, ApiClient::ApiError => e
          @stderr.puts "Error: #{e.message}"
          1
        rescue => e
          @stderr.puts "Error: #{e.message}"
          1
        end

        private

        def parse_options
          OptionParser.new do |opts|
            opts.banner = "Usage: raygatherer recording download <name> [options]"
            opts.separator ""
            opts.separator "Options:"

            opts.on("--qmdl", "Download as qmdl format (default)") do
              @format_flags << :qmdl
            end

            opts.on("--pcap", "Download as pcap format") do
              @format_flags << :pcap
            end

            opts.on("--zip", "Download as zip format (qmdl + pcapng)") do
              @format_flags << :zip
            end

            opts.on("-h", "--help", "Show this help message") do
              show_help
              raise CLI::EarlyExit, 0
            end
          end.parse!(@argv)
        end

        def validate_format_flags
          if @format_flags.length > 1
            @stderr.puts "Error: only one format flag (--qmdl, --pcap, --zip) may be specified"
            return false
          end
          @format = @format_flags.first || :qmdl
          true
        end

        def resolve_destination(name)
          ext = EXTENSIONS[@format]
          dir = @download_dir || "."
          File.join(dir, "#{name}#{ext}")
        end

        def download_to_file(name, dest_path)
          File.open(dest_path, "wb") do |file|
            @api_client.download_recording(name, format: @format, io: file)
          end
        rescue StandardError
          File.delete(dest_path) if File.exist?(dest_path)
          raise
        end

        def format_size(bytes)
          if bytes < 1024
            "#{bytes} B"
          elsif bytes < 1024 * 1024
            "#{(bytes / 1024.0).round(1)} KB"
          elsif bytes < 1024 * 1024 * 1024
            "#{(bytes / (1024.0 * 1024)).round(1)} MB"
          else
            "#{(bytes / (1024.0 * 1024 * 1024)).round(1)} GB"
          end
        end

        def show_help(output = @stdout)
          output.puts "Usage: raygatherer [global options] recording download <name> [options]"
          output.puts ""
          output.puts "Downloads a recording from the rayhunter device."
          output.puts ""
          output.puts "Format (default: --qmdl):"
          output.puts "        --qmdl                       Download as qmdl format (default)"
          output.puts "        --pcap                       Download as pcap format"
          output.puts "        --zip                        Download as zip format (qmdl + pcapng)"
          output.puts ""
          output.puts "Options:"
          output.puts "    -h, --help                       Show this help message"
          output.puts ""
          output.puts "Global options (see 'raygatherer --help'):"
          output.puts "    --host, --basic-auth-user, --basic-auth-password, --verbose"
          output.puts ""
          output.puts "Examples:"
          output.puts "  raygatherer --host http://192.168.1.100:8080 recording download 1738950000"
          output.puts "  raygatherer --host http://192.168.1.100:8080 recording download 1738950000 --pcap"
          output.puts "  raygatherer --host http://192.168.1.100:8080 recording download 1738950000 --zip"
        end
      end
    end
  end
end
