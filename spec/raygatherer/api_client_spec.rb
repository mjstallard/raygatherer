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
      no_recording = { "entries" => manifest_response["entries"], "current_entry" => nil }
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
end
