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
end
