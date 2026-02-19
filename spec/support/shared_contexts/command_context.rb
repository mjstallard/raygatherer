# frozen_string_literal: true

RSpec.shared_context "command context" do
  let(:stdout) { StringIO.new }
  let(:stderr) { StringIO.new }
  let(:api_client) { instance_double(Raygatherer::ApiClient) }
end
