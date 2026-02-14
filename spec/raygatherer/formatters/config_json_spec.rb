# frozen_string_literal: true

RSpec.describe Raygatherer::Formatters::ConfigJSON do
  describe "#format" do
    it "outputs valid JSON" do
      config = {"port" => 8080}

      output = described_class.new.format(config)

      expect { ::JSON.parse(output) }.not_to raise_error
    end

    it "preserves all fields" do
      config = {
        "qmdl_store_path" => "/data/rayhunter",
        "port" => 8080,
        "readonly_port" => 8081,
        "notification_url" => nil,
        "analyzers" => {
          "null_cipher" => true,
          "imsi_catcher" => true
        }
      }

      output = described_class.new.format(config)

      parsed = ::JSON.parse(output)
      expect(parsed["port"]).to eq(8080)
      expect(parsed["analyzers"]["null_cipher"]).to be true
      expect(parsed["notification_url"]).to be_nil
    end
  end
end
