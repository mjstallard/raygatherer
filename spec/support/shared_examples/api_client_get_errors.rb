# frozen_string_literal: true

RSpec.shared_examples "API client GET error handling" do |path:, method_call:|
  it "handles HTTP errors" do
    stub_request(:get, "#{host}#{path}")
      .to_return(status: 500, body: "Internal Server Error")

    expect { method_call.call(client) }.to raise_error(
      Raygatherer::ApiClient::ApiError,
      /Server returned 500/
    )
  end

  it "handles connection errors" do
    stub_request(:get, "#{host}#{path}")
      .to_raise(SocketError.new("Failed to open TCP connection"))

    expect { method_call.call(client) }.to raise_error(
      Raygatherer::ApiClient::ConnectionError,
      /Failed to connect/
    )
  end

  it "handles malformed JSON" do
    stub_request(:get, "#{host}#{path}")
      .to_return(status: 200, body: "not json")

    expect { method_call.call(client) }.to raise_error(
      Raygatherer::ApiClient::ParseError,
      /Failed to parse/
    )
  end

  it "sends basic auth credentials when configured" do
    auth_client = described_class.new(host, username: "user", password: "pass")

    stub_request(:get, "#{host}#{path}")
      .with(basic_auth: ["user", "pass"])
      .to_return(status: 200, body: success_body)

    expect { method_call.call(auth_client) }.not_to raise_error
  end
end

RSpec.shared_examples "API client POST error handling" do |path:, method_call:, expected_code: "202"|
  it "raises ApiError on non-#{expected_code} response" do
    stub_request(:post, "#{host}#{path}")
      .to_return(status: 400, body: "Bad Request")

    expect { method_call.call(client) }.to raise_error(
      Raygatherer::ApiClient::ApiError,
      /Server returned 400/
    )
  end

  it "raises ConnectionError on connection failure" do
    stub_request(:post, "#{host}#{path}")
      .to_raise(SocketError.new("Failed to open TCP connection"))

    expect { method_call.call(client) }.to raise_error(
      Raygatherer::ApiClient::ConnectionError,
      /Failed to connect/
    )
  end

  it "sends basic auth credentials when configured" do
    auth_client = described_class.new(host, username: "user", password: "pass")
    body = defined?(success_body) ? success_body : ""

    stub_request(:post, "#{host}#{path}")
      .with(basic_auth: ["user", "pass"])
      .to_return(status: expected_code.to_i, body: body)

    expect { method_call.call(auth_client) }.not_to raise_error
  end
end
