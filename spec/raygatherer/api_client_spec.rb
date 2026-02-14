# frozen_string_literal: true

require "webmock/rspec"

RSpec.describe Raygatherer::ApiClient do
  let(:host) { "http://localhost:8080" }
  let(:client) { described_class.new(host) }

  describe "#initialize" do
    let(:valid_ndjson) do
      <<~NDJSON.chomp
        {"analyzers":[],"rayhunter":{},"report_version":2}
        {"events":[null]}
      NDJSON
    end

    it "normalizes host by adding http:// if missing" do
      client = described_class.new("rayhunter.example.com")
      stub_request(:get, "http://rayhunter.example.com/api/analysis-report/live")
        .to_return(status: 200, body: valid_ndjson)

      # If URL is properly normalized, the stub will be matched
      result = client.fetch_live_analysis_report
      expect(result).to have_key(:metadata)
      expect(result).to have_key(:rows)
    end

    it "preserves http:// scheme if already present" do
      client = described_class.new("http://rayhunter.example.com")
      stub_request(:get, "http://rayhunter.example.com/api/analysis-report/live")
        .to_return(status: 200, body: valid_ndjson)

      result = client.fetch_live_analysis_report
      expect(result).to have_key(:metadata)
    end

    it "preserves https:// scheme if present" do
      client = described_class.new("https://rayhunter.example.com")
      stub_request(:get, "https://rayhunter.example.com/api/analysis-report/live")
        .to_return(status: 200, body: valid_ndjson)

      result = client.fetch_live_analysis_report
      expect(result).to have_key(:metadata)
    end

    it "accepts username and password for basic auth" do
      client = described_class.new("http://rayhunter.example.com",
        username: "user",
        password: "pass")

      stub_request(:get, "http://rayhunter.example.com/api/analysis-report/live")
        .with(basic_auth: ["user", "pass"])
        .to_return(status: 200, body: valid_ndjson)

      result = client.fetch_live_analysis_report
      expect(result).to have_key(:metadata)
    end

    it "makes unauthenticated requests when no credentials provided" do
      client = described_class.new("http://rayhunter.example.com")

      # Should NOT send basic_auth header
      stub_request(:get, "http://rayhunter.example.com/api/analysis-report/live")
        .to_return(status: 200, body: valid_ndjson)

      result = client.fetch_live_analysis_report
      expect(result).to have_key(:metadata)
    end
  end

  describe "#fetch_live_analysis_report" do
    let(:ndjson_response) do
      <<~NDJSON.chomp
        {"analyzers":[{"name":"test","description":"Test analyzer","version":1}],"rayhunter":{"rayhunter_version":"1.0.0","system_os":"Linux","arch":"x86_64"},"report_version":2}
        {"packet_timestamp":"2024-02-07T14:25:32Z","events":[null,{"event_type":"Medium","message":"Connection redirect to 2G detected"}]}
        {"packet_timestamp":"2024-02-07T14:25:33Z","events":[null]}
      NDJSON
    end

    it "parses NDJSON response into structured data" do
      stub_request(:get, "#{host}/api/analysis-report/live")
        .to_return(status: 200, body: ndjson_response)

      result = client.fetch_live_analysis_report

      expect(result).to have_key(:metadata)
      expect(result).to have_key(:rows)
      expect(result[:metadata]["report_version"]).to eq(2)
      expect(result[:rows]).to be_an(Array)
      expect(result[:rows].length).to eq(2)
    end

    it "returns metadata and rows separately" do
      stub_request(:get, "#{host}/api/analysis-report/live")
        .to_return(status: 200, body: ndjson_response)

      result = client.fetch_live_analysis_report

      expect(result[:metadata]).to include("analyzers", "rayhunter", "report_version")
      expect(result[:rows].first).to include("packet_timestamp", "events")
    end

    it "handles HTTP errors gracefully" do
      stub_request(:get, "#{host}/api/analysis-report/live")
        .to_return(status: 500, body: "Internal Server Error")

      expect { client.fetch_live_analysis_report }.to raise_error(
        Raygatherer::ApiClient::ApiError,
        /Server returned 500/
      )
    end

    it "handles connection errors" do
      stub_request(:get, "#{host}/api/analysis-report/live")
        .to_raise(SocketError.new("Failed to open TCP connection"))

      expect { client.fetch_live_analysis_report }.to raise_error(
        Raygatherer::ApiClient::ConnectionError,
        /Failed to connect/
      )
    end

    it "handles malformed JSON" do
      stub_request(:get, "#{host}/api/analysis-report/live")
        .to_return(status: 200, body: "not json\n{invalid")

      expect { client.fetch_live_analysis_report }.to raise_error(
        Raygatherer::ApiClient::ParseError,
        /Failed to parse/
      )
    end

    it "handles empty response" do
      stub_request(:get, "#{host}/api/analysis-report/live")
        .to_return(status: 200, body: "")

      expect { client.fetch_live_analysis_report }.to raise_error(
        Raygatherer::ApiClient::ParseError,
        /No data/
      )
    end

    it "handles 401 Unauthorized with basic auth" do
      stub_request(:get, "#{host}/api/analysis-report/live")
        .to_return(status: 401, body: "Unauthorized")

      expect { client.fetch_live_analysis_report }.to raise_error(
        Raygatherer::ApiClient::ApiError,
        /Server returned 401/
      )
    end
  end

  describe "verbose logging" do
    let(:stderr) { StringIO.new }
    let(:verbose_client) { described_class.new(host, verbose: true, stderr: stderr) }

    let(:ndjson_response) do
      <<~NDJSON.chomp
        {"report_version":2}
        {"events":[null]}
      NDJSON
    end

    it "accepts verbose and stderr parameters" do
      expect { verbose_client }.not_to raise_error
    end

    it "defaults verbose to false and stderr to $stderr" do
      client = described_class.new(host)
      expect(client.instance_variable_get(:@verbose)).to eq(false)
      expect(client.instance_variable_get(:@stderr)).to eq($stderr)
    end

    describe "verbose output" do
      it "logs HTTP request details" do
        stub_request(:get, "#{host}/api/analysis-report/live")
          .to_return(status: 200, body: ndjson_response)

        verbose_client.fetch_live_analysis_report

        expect(stderr.string).to include("HTTP GET #{host}/api/analysis-report/live")
      end

      it "logs request timing" do
        stub_request(:get, "#{host}/api/analysis-report/live")
          .to_return(status: 200, body: ndjson_response)

        verbose_client.fetch_live_analysis_report

        expect(stderr.string).to match(/Request started at:/)
        expect(stderr.string).to match(/Response received: 200 OK \(\d+\.\d+s\)/)
      end

      it "logs raw response body BEFORE parsing" do
        stub_request(:get, "#{host}/api/analysis-report/live")
          .to_return(status: 200, body: ndjson_response)

        verbose_client.fetch_live_analysis_report

        output = stderr.string
        expect(output).to include("Raw response body")
        expect(output).to include('{"report_version":2}')
        expect(output).to include('{"events":[null]}')

        # Verify raw body appears BEFORE parsing message
        raw_index = output.index("Raw response body")
        parse_index = output.index("Parsing NDJSON")
        expect(raw_index).to be < parse_index
      end

      it "logs basic auth username (but not password)" do
        auth_client = described_class.new(
          host,
          username: "testuser",
          password: "secret123",
          verbose: true,
          stderr: stderr
        )

        stub_request(:get, "#{host}/api/analysis-report/live")
          .with(basic_auth: ["testuser", "secret123"])
          .to_return(status: 200, body: ndjson_response)

        auth_client.fetch_live_analysis_report

        expect(stderr.string).to include("Basic Auth: user=testuser")
        expect(stderr.string).not_to include("secret123")
      end

      it "logs parse success" do
        stub_request(:get, "#{host}/api/analysis-report/live")
          .to_return(status: 200, body: ndjson_response)

        verbose_client.fetch_live_analysis_report

        expect(stderr.string).to match(/Parsed successfully: metadata \+ \d+ rows?/)
      end
    end

    describe "verbose output on errors" do
      it "logs raw body even when parse fails (CRITICAL BUG FIX)" do
        bad_json = "{invalid json here}"

        stub_request(:get, "#{host}/api/analysis-report/live")
          .to_return(status: 200, body: bad_json)

        expect { verbose_client.fetch_live_analysis_report }.to raise_error(
          Raygatherer::ApiClient::ParseError
        )

        # CRITICAL: Raw body must be logged BEFORE parse attempt
        output = stderr.string
        expect(output).to include("Raw response body")
        expect(output).to include("{invalid json here}")
        expect(output).to include("Parse failed:")
      end

      it "logs connection errors" do
        stub_request(:get, "#{host}/api/analysis-report/live")
          .to_raise(SocketError.new("Failed to open TCP connection"))

        expect { verbose_client.fetch_live_analysis_report }.to raise_error(
          Raygatherer::ApiClient::ConnectionError
        )

        output = stderr.string
        expect(output).to include("HTTP GET #{host}/api/analysis-report/live")
        expect(output).to include("Connection error:")
      end

      it "logs HTTP error responses with body" do
        stub_request(:get, "#{host}/api/analysis-report/live")
          .to_return(status: 500, body: "Internal Server Error")

        expect { verbose_client.fetch_live_analysis_report }.to raise_error(
          Raygatherer::ApiClient::ApiError
        )

        output = stderr.string
        expect(output).to include("Response received: 500")
        expect(output).to include("Raw response body")
        expect(output).to include("Internal Server Error")
      end
    end

    describe "non-verbose mode" do
      it "does not log when verbose is false" do
        non_verbose_client = described_class.new(host, verbose: false, stderr: stderr)

        stub_request(:get, "#{host}/api/analysis-report/live")
          .to_return(status: 200, body: ndjson_response)

        non_verbose_client.fetch_live_analysis_report

        expect(stderr.string).to be_empty
      end
    end
  end

  describe "#fetch_manifest" do
    let(:manifest_response) do
      {
        "entries" => [
          {
            "name" => "1738950000",
            "start_time" => "2025-02-07T13:40:00+00:00",
            "last_message_time" => "2025-02-07T15:30:00+00:00",
            "qmdl_size_bytes" => 134_963_200,
            "rayhunter_version" => "0.4.0",
            "system_os" => "Linux",
            "arch" => "aarch64"
          }
        ],
        "current_entry" => {
          "name" => "1738956789",
          "start_time" => "2025-02-07T15:33:09+00:00",
          "last_message_time" => "2025-02-07T16:00:00+00:00",
          "qmdl_size_bytes" => 47_513_600,
          "rayhunter_version" => "0.4.0",
          "system_os" => "Linux",
          "arch" => "aarch64"
        }
      }
    end

    it "parses JSON response into a hash with entries and current_entry" do
      stub_request(:get, "#{host}/api/qmdl-manifest")
        .to_return(status: 200, body: ::JSON.generate(manifest_response))

      result = client.fetch_manifest

      expect(result).to have_key("entries")
      expect(result).to have_key("current_entry")
      expect(result["entries"]).to be_an(Array)
      expect(result["entries"].length).to eq(1)
      expect(result["entries"].first["name"]).to eq("1738950000")
    end

    it "returns current_entry when present" do
      stub_request(:get, "#{host}/api/qmdl-manifest")
        .to_return(status: 200, body: ::JSON.generate(manifest_response))

      result = client.fetch_manifest

      expect(result["current_entry"]).not_to be_nil
      expect(result["current_entry"]["name"]).to eq("1738956789")
    end

    it "returns null current_entry when not recording" do
      no_recording = {"entries" => manifest_response["entries"], "current_entry" => nil}
      stub_request(:get, "#{host}/api/qmdl-manifest")
        .to_return(status: 200, body: ::JSON.generate(no_recording))

      result = client.fetch_manifest

      expect(result["current_entry"]).to be_nil
    end

    it "handles HTTP errors" do
      stub_request(:get, "#{host}/api/qmdl-manifest")
        .to_return(status: 500, body: "Internal Server Error")

      expect { client.fetch_manifest }.to raise_error(
        Raygatherer::ApiClient::ApiError,
        /Server returned 500/
      )
    end

    it "handles connection errors" do
      stub_request(:get, "#{host}/api/qmdl-manifest")
        .to_raise(SocketError.new("Failed to open TCP connection"))

      expect { client.fetch_manifest }.to raise_error(
        Raygatherer::ApiClient::ConnectionError,
        /Failed to connect/
      )
    end

    it "handles malformed JSON" do
      stub_request(:get, "#{host}/api/qmdl-manifest")
        .to_return(status: 200, body: "not json")

      expect { client.fetch_manifest }.to raise_error(
        Raygatherer::ApiClient::ParseError,
        /Failed to parse/
      )
    end

    it "sends basic auth credentials when configured" do
      auth_client = described_class.new(host, username: "user", password: "pass")

      stub_request(:get, "#{host}/api/qmdl-manifest")
        .with(basic_auth: ["user", "pass"])
        .to_return(status: 200, body: ::JSON.generate(manifest_response))

      result = auth_client.fetch_manifest

      expect(result["entries"]).to be_an(Array)
    end
  end

  describe "#fetch_system_stats" do
    let(:stats_response) do
      {
        "disk_stats" => {"partition" => "/dev/sda1", "total_size" => "128G", "used_size" => "64G",
                         "available_size" => "64G", "used_percent" => "50%", "mounted_on" => "/data"},
        "memory_stats" => {"total" => "28.3M", "used" => "15.1M", "free" => "13.2M"},
        "runtime_metadata" => {"rayhunter_version" => "1.2.3", "system_os" => "Linux 3.18.48", "arch" => "armv7l"},
        "battery_status" => {"level" => 85, "is_plugged_in" => true}
      }
    end

    it "parses JSON response into a hash" do
      stub_request(:get, "#{host}/api/system-stats")
        .to_return(status: 200, body: ::JSON.generate(stats_response))

      result = client.fetch_system_stats

      expect(result).to have_key("disk_stats")
      expect(result).to have_key("memory_stats")
      expect(result).to have_key("runtime_metadata")
      expect(result["disk_stats"]["total_size"]).to eq("128G")
    end

    it "handles optional battery_status" do
      no_battery = stats_response.except("battery_status")
      stub_request(:get, "#{host}/api/system-stats")
        .to_return(status: 200, body: ::JSON.generate(no_battery))

      result = client.fetch_system_stats

      expect(result).not_to have_key("battery_status")
      expect(result["disk_stats"]["total_size"]).to eq("128G")
    end

    it "handles HTTP errors" do
      stub_request(:get, "#{host}/api/system-stats")
        .to_return(status: 500, body: "Internal Server Error")

      expect { client.fetch_system_stats }.to raise_error(
        Raygatherer::ApiClient::ApiError,
        /Server returned 500/
      )
    end

    it "handles connection errors" do
      stub_request(:get, "#{host}/api/system-stats")
        .to_raise(SocketError.new("Failed to open TCP connection"))

      expect { client.fetch_system_stats }.to raise_error(
        Raygatherer::ApiClient::ConnectionError,
        /Failed to connect/
      )
    end

    it "handles malformed JSON" do
      stub_request(:get, "#{host}/api/system-stats")
        .to_return(status: 200, body: "not json")

      expect { client.fetch_system_stats }.to raise_error(
        Raygatherer::ApiClient::ParseError,
        /Failed to parse/
      )
    end

    it "sends basic auth credentials when configured" do
      auth_client = described_class.new(host, username: "user", password: "pass")

      stub_request(:get, "#{host}/api/system-stats")
        .with(basic_auth: ["user", "pass"])
        .to_return(status: 200, body: ::JSON.generate(stats_response))

      result = auth_client.fetch_system_stats

      expect(result["disk_stats"]).to be_a(Hash)
    end
  end

  describe "#download_recording" do
    let(:recording_name) { "1738950000" }
    let(:binary_content) { "\x00\x01\x02\x03\x04".b }
    let(:io) { StringIO.new }

    it "streams body bytes to the given IO for qmdl format" do
      stub_request(:get, "#{host}/api/qmdl/#{recording_name}")
        .to_return(status: 200, body: binary_content)

      client.download_recording(recording_name, format: :qmdl, io: io)

      expect(io.string.b).to eq(binary_content)
    end

    it "uses /api/qmdl path for qmdl format (default)" do
      stub_request(:get, "#{host}/api/qmdl/#{recording_name}")
        .to_return(status: 200, body: binary_content)

      client.download_recording(recording_name, io: io)

      expect(WebMock).to have_requested(:get, "#{host}/api/qmdl/#{recording_name}")
    end

    it "uses /api/pcap path for pcap format" do
      stub_request(:get, "#{host}/api/pcap/#{recording_name}")
        .to_return(status: 200, body: binary_content)

      client.download_recording(recording_name, format: :pcap, io: io)

      expect(WebMock).to have_requested(:get, "#{host}/api/pcap/#{recording_name}")
    end

    it "uses /api/zip path for zip format" do
      stub_request(:get, "#{host}/api/zip/#{recording_name}")
        .to_return(status: 200, body: binary_content)

      client.download_recording(recording_name, format: :zip, io: io)

      expect(WebMock).to have_requested(:get, "#{host}/api/zip/#{recording_name}")
    end

    it "raises ApiError on 404" do
      stub_request(:get, "#{host}/api/qmdl/#{recording_name}")
        .to_return(status: 404, body: "Not Found")

      expect { client.download_recording(recording_name, io: io) }.to raise_error(
        Raygatherer::ApiClient::ApiError,
        /Server returned 404/
      )
    end

    it "raises ConnectionError on connection failure" do
      stub_request(:get, "#{host}/api/qmdl/#{recording_name}")
        .to_raise(SocketError.new("Failed to open TCP connection"))

      expect { client.download_recording(recording_name, io: io) }.to raise_error(
        Raygatherer::ApiClient::ConnectionError,
        /Failed to connect/
      )
    end

    it "sends basic auth credentials when configured" do
      auth_client = described_class.new(host, username: "user", password: "pass")

      stub_request(:get, "#{host}/api/qmdl/#{recording_name}")
        .with(basic_auth: ["user", "pass"])
        .to_return(status: 200, body: binary_content)

      auth_client.download_recording(recording_name, io: io)

      expect(io.string.b).to eq(binary_content)
    end
  end

  describe "#delete_recording" do
    let(:recording_name) { "1738950000" }

    it "POSTs to the delete recording endpoint" do
      stub_request(:post, "#{host}/api/delete-recording/#{recording_name}")
        .to_return(status: 202, body: "")

      client.delete_recording(recording_name)

      expect(WebMock).to have_requested(:post, "#{host}/api/delete-recording/#{recording_name}")
    end

    it "raises ApiError on non-202 response" do
      stub_request(:post, "#{host}/api/delete-recording/#{recording_name}")
        .to_return(status: 400, body: "Not Found")

      expect { client.delete_recording(recording_name) }.to raise_error(
        Raygatherer::ApiClient::ApiError,
        /Server returned 400/
      )
    end

    it "raises ConnectionError on connection failure" do
      stub_request(:post, "#{host}/api/delete-recording/#{recording_name}")
        .to_raise(SocketError.new("Failed to open TCP connection"))

      expect { client.delete_recording(recording_name) }.to raise_error(
        Raygatherer::ApiClient::ConnectionError,
        /Failed to connect/
      )
    end

    it "sends basic auth credentials when configured" do
      auth_client = described_class.new(host, username: "user", password: "pass")

      stub_request(:post, "#{host}/api/delete-recording/#{recording_name}")
        .with(basic_auth: ["user", "pass"])
        .to_return(status: 202, body: "")

      auth_client.delete_recording(recording_name)
    end
  end

  describe "URL-encoding recording names" do
    it "URL-encodes recording name with spaces in download path" do
      stub_request(:get, "#{host}/api/qmdl/my+recording")
        .to_return(status: 200, body: "data")

      io = StringIO.new
      client.download_recording("my recording", format: :qmdl, io: io)

      expect(WebMock).to have_requested(:get, "#{host}/api/qmdl/my+recording")
    end

    it "URL-encodes recording name with special chars in delete path" do
      stub_request(:post, "#{host}/api/delete-recording/foo%2Fbar%3Fbaz")
        .to_return(status: 202, body: "")

      client.delete_recording("foo/bar?baz")

      expect(WebMock).to have_requested(:post, "#{host}/api/delete-recording/foo%2Fbar%3Fbaz")
    end

    it "numeric names are unchanged by encoding" do
      stub_request(:get, "#{host}/api/qmdl/1738950000")
        .to_return(status: 200, body: "data")

      io = StringIO.new
      client.download_recording("1738950000", format: :qmdl, io: io)

      expect(WebMock).to have_requested(:get, "#{host}/api/qmdl/1738950000")
    end
  end

  describe "#stop_recording" do
    it "POSTs to the stop recording endpoint" do
      stub_request(:post, "#{host}/api/stop-recording")
        .to_return(status: 202, body: "")

      client.stop_recording

      expect(WebMock).to have_requested(:post, "#{host}/api/stop-recording")
    end

    it "raises ApiError on non-202 response" do
      stub_request(:post, "#{host}/api/stop-recording")
        .to_return(status: 500, body: "Internal Server Error")

      expect { client.stop_recording }.to raise_error(
        Raygatherer::ApiClient::ApiError,
        /Server returned 500/
      )
    end

    it "raises ConnectionError on connection failure" do
      stub_request(:post, "#{host}/api/stop-recording")
        .to_raise(SocketError.new("Failed to open TCP connection"))

      expect { client.stop_recording }.to raise_error(
        Raygatherer::ApiClient::ConnectionError,
        /Failed to connect/
      )
    end

    it "sends basic auth credentials when configured" do
      auth_client = described_class.new(host, username: "user", password: "pass")

      stub_request(:post, "#{host}/api/stop-recording")
        .with(basic_auth: ["user", "pass"])
        .to_return(status: 202, body: "")

      auth_client.stop_recording
    end
  end

  describe "error messages include response body" do
    it "GET error includes response body text" do
      stub_request(:get, "#{host}/api/analysis-report/live")
        .to_return(status: 503, body: "No QMDL data's being recorded to analyze, try starting a new recording!")

      expect { client.fetch_live_analysis_report }.to raise_error(
        Raygatherer::ApiClient::ApiError,
        /No QMDL data's being recorded/
      )
    end

    it "POST error includes response body text" do
      stub_request(:post, "#{host}/api/delete-recording/1738950000")
        .to_return(status: 400, body: "no recording with that name")

      expect { client.delete_recording("1738950000") }.to raise_error(
        Raygatherer::ApiClient::ApiError,
        /no recording with that name/
      )
    end

    it "streaming error includes response body text" do
      stub_request(:get, "#{host}/api/qmdl/1738950000")
        .to_return(status: 404, body: "Couldn't find QMDL entry with name \"1738950000\"")

      io = StringIO.new
      expect { client.download_recording("1738950000", io: io) }.to raise_error(
        Raygatherer::ApiClient::ApiError,
        /Couldn't find QMDL entry/
      )
    end

    it "falls back to HTTP status text when body is empty" do
      stub_request(:get, "#{host}/api/analysis-report/live")
        .to_return(status: [500, "Internal Server Error"], body: "")

      expect { client.fetch_live_analysis_report }.to raise_error(
        Raygatherer::ApiClient::ApiError,
        /Server returned 500: Internal Server Error/
      )
    end
  end

  describe "#start_recording" do
    it "POSTs to the start recording endpoint" do
      stub_request(:post, "#{host}/api/start-recording")
        .to_return(status: 202, body: "")

      client.start_recording

      expect(WebMock).to have_requested(:post, "#{host}/api/start-recording")
    end

    it "raises ApiError on non-202 response" do
      stub_request(:post, "#{host}/api/start-recording")
        .to_return(status: 500, body: "Internal Server Error")

      expect { client.start_recording }.to raise_error(
        Raygatherer::ApiClient::ApiError,
        /Server returned 500/
      )
    end

    it "raises ConnectionError on connection failure" do
      stub_request(:post, "#{host}/api/start-recording")
        .to_raise(SocketError.new("Failed to open TCP connection"))

      expect { client.start_recording }.to raise_error(
        Raygatherer::ApiClient::ConnectionError,
        /Failed to connect/
      )
    end

    it "sends basic auth credentials when configured" do
      auth_client = described_class.new(host, username: "user", password: "pass")

      stub_request(:post, "#{host}/api/start-recording")
        .with(basic_auth: ["user", "pass"])
        .to_return(status: 202, body: "")

      auth_client.start_recording
    end
  end

  describe "#fetch_analysis_report" do
    let(:ndjson_response) do
      <<~NDJSON.chomp
        {"analyzers":[{"name":"test","description":"Test analyzer","version":1}],"rayhunter":{},"report_version":2}
        {"packet_timestamp":"2024-02-07T14:25:32Z","events":[null,{"event_type":"Medium","message":"Connection redirect"}]}
      NDJSON
    end

    it "parses NDJSON response from /api/analysis-report/{name}" do
      stub_request(:get, "#{host}/api/analysis-report/my_recording")
        .to_return(status: 200, body: ndjson_response)

      result = client.fetch_analysis_report("my_recording")

      expect(result).to have_key(:metadata)
      expect(result).to have_key(:rows)
      expect(result[:rows].length).to eq(1)
    end

    it "URL-encodes the recording name" do
      stub_request(:get, "#{host}/api/analysis-report/my+recording")
        .to_return(status: 200, body: ndjson_response)

      result = client.fetch_analysis_report("my recording")

      expect(result).to have_key(:metadata)
    end

    it "handles HTTP errors" do
      stub_request(:get, "#{host}/api/analysis-report/my_recording")
        .to_return(status: 404, body: "Not Found")

      expect { client.fetch_analysis_report("my_recording") }.to raise_error(
        Raygatherer::ApiClient::ApiError,
        /Server returned 404/
      )
    end

    it "handles connection errors" do
      stub_request(:get, "#{host}/api/analysis-report/my_recording")
        .to_raise(SocketError.new("Failed to open TCP connection"))

      expect { client.fetch_analysis_report("my_recording") }.to raise_error(
        Raygatherer::ApiClient::ConnectionError,
        /Failed to connect/
      )
    end

    it "sends basic auth credentials when configured" do
      auth_client = described_class.new(host, username: "user", password: "pass")

      stub_request(:get, "#{host}/api/analysis-report/my_recording")
        .with(basic_auth: ["user", "pass"])
        .to_return(status: 200, body: ndjson_response)

      result = auth_client.fetch_analysis_report("my_recording")

      expect(result).to have_key(:metadata)
    end
  end

  describe "#fetch_analysis_status" do
    let(:analysis_status_response) do
      {
        "queued" => ["rec1", "rec2"],
        "running" => "rec3",
        "finished" => ["rec4", "rec5"]
      }
    end

    it "parses JSON response from /api/analysis" do
      stub_request(:get, "#{host}/api/analysis")
        .to_return(status: 200, body: ::JSON.generate(analysis_status_response))

      result = client.fetch_analysis_status

      expect(result["queued"]).to eq(["rec1", "rec2"])
      expect(result["running"]).to eq("rec3")
      expect(result["finished"]).to eq(["rec4", "rec5"])
    end

    it "handles null running field" do
      response = analysis_status_response.merge("running" => nil)
      stub_request(:get, "#{host}/api/analysis")
        .to_return(status: 200, body: ::JSON.generate(response))

      result = client.fetch_analysis_status

      expect(result["running"]).to be_nil
    end

    it "handles HTTP errors" do
      stub_request(:get, "#{host}/api/analysis")
        .to_return(status: 500, body: "Internal Server Error")

      expect { client.fetch_analysis_status }.to raise_error(
        Raygatherer::ApiClient::ApiError,
        /Server returned 500/
      )
    end

    it "handles connection errors" do
      stub_request(:get, "#{host}/api/analysis")
        .to_raise(SocketError.new("Failed to open TCP connection"))

      expect { client.fetch_analysis_status }.to raise_error(
        Raygatherer::ApiClient::ConnectionError,
        /Failed to connect/
      )
    end

    it "sends basic auth credentials when configured" do
      auth_client = described_class.new(host, username: "user", password: "pass")

      stub_request(:get, "#{host}/api/analysis")
        .with(basic_auth: ["user", "pass"])
        .to_return(status: 200, body: ::JSON.generate(analysis_status_response))

      result = auth_client.fetch_analysis_status

      expect(result["queued"]).to eq(["rec1", "rec2"])
    end
  end
end
