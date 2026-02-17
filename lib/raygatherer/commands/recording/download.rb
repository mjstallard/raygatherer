# frozen_string_literal: true

require "optparse"
require_relative "../base"
require_relative "../../format_helpers"
require_relative "../../spinner"

module Raygatherer
  module Commands
    module Recording
      class Download < Base
        include FormatHelpers

        EXTENSIONS = {
          qmdl: ".qmdl",
          pcap: ".pcap",
          zip: ".zip"
        }.freeze

        def initialize(argv, stdout: $stdout, stderr: $stderr, api_client: nil)
          super
          @format = nil
          @format_flags = []
          @download_dir = nil
          @save_as = nil
        end

        def run
          with_error_handling do
            parse_options
            next EXIT_CODE_ERROR unless validate_format_flags
            next EXIT_CODE_ERROR unless validate_path_flags

            name = @argv.shift
            unless name
              @stderr.puts "Error: recording name is required"
              next EXIT_CODE_ERROR
            end

            dest_path = resolve_destination(name)
            next EXIT_CODE_ERROR unless dest_path

            if File.exist?(dest_path)
              @stderr.puts "Error: file already exists: #{dest_path}"
              next EXIT_CODE_ERROR
            end

            spinner = Spinner.new(stderr: @stderr)
            spinner.spin
            begin
              download_to_file(name, dest_path)
            ensure
              spinner.stop
            end

            size = File.size(dest_path)
            @stdout.puts "#{dest_path} (#{format_size(size)})"
            EXIT_CODE_SUCCESS
          end
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

            opts.on("--download-dir DIR", "Save to specified directory") do |dir|
              @download_dir = dir
            end

            opts.on("--save-as PATH", "Save to exact file path") do |path|
              @save_as = path
            end

            opts.on("-h", "--help", "Show this help message") do
              show_help
              raise CLI::EarlyExit, EXIT_CODE_SUCCESS
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

        def validate_path_flags
          if @download_dir && @save_as
            @stderr.puts "Error: --download-dir and --save-as are mutually exclusive"
            return false
          end
          if @download_dir && !Dir.exist?(@download_dir)
            @stderr.puts "Error: directory does not exist: #{@download_dir}"
            return false
          end
          if @save_as && !Dir.exist?(File.dirname(@save_as))
            @stderr.puts "Error: directory does not exist: #{File.dirname(@save_as)}"
            return false
          end
          true
        end

        def resolve_destination(name)
          return @save_as if @save_as

          ext = EXTENSIONS[@format]
          dir = @download_dir || "."
          File.join(dir, "#{name}#{ext}")
        end

        def download_to_file(name, dest_path)
          File.open(dest_path, "wb") do |file|
            @api_client.download_recording(name, format: @format, io: file)
          end
        rescue
          File.delete(dest_path) if File.exist?(dest_path)
          raise
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
          output.puts "Destination:"
          output.puts "        --download-dir DIR            Save to specified directory (default: .)"
          output.puts "        --save-as PATH               Save to exact file path"
          output.puts ""
          output.puts "Options:"
          output.puts "    -h, --help                       Show this help message"
          output.puts ""
          print_global_options(output)
          output.puts ""
          output.puts "Examples:"
          output.puts "  raygatherer --host http://192.168.1.100:8080 recording download 1738950000"
          output.puts "  raygatherer --host http://192.168.1.100:8080 recording download 1738950000 --pcap"
          output.puts "  raygatherer --host http://192.168.1.100:8080 recording download 1738950000 --download-dir /tmp"
          output.puts "  raygatherer --host http://192.168.1.100:8080 recording download 1738950000 --save-as my.qmdl"
        end
      end
    end
  end
end
