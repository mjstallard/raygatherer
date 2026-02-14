# frozen_string_literal: true

RSpec.describe Raygatherer::Formatters::ConfigHuman do
  describe "#format" do
    let(:full_config) do
      {
        "qmdl_store_path" => "/data/rayhunter",
        "port" => 8080,
        "readonly_port" => 8081,
        "notification_url" => "https://example.com/notify",
        "analyzers" => {
          "null_cipher" => true,
          "imsi_catcher" => false
        }
      }
    end

    it "shows port" do
      output = described_class.new.format(full_config)

      expect(output).to include("Port: 8080")
    end

    it "shows readonly port" do
      output = described_class.new.format(full_config)

      expect(output).to include("Readonly port: 8081")
    end

    it "shows QMDL store path" do
      output = described_class.new.format(full_config)

      expect(output).to include("QMDL store path: /data/rayhunter")
    end

    it "shows notification URL when set" do
      output = described_class.new.format(full_config)

      expect(output).to include("Notification URL: https://example.com/notify")
    end

    it "shows (not set) when notification URL is nil" do
      config = full_config.merge("notification_url" => nil)

      output = described_class.new.format(config)

      expect(output).to include("Notification URL: (not set)")
    end

    it "shows analyzers section" do
      output = described_class.new.format(full_config)

      expect(output).to include("Analyzers:")
      expect(output).to include("  null_cipher: enabled")
      expect(output).to include("  imsi_catcher: disabled")
    end

    it "handles missing analyzers" do
      config = full_config.except("analyzers")

      output = described_class.new.format(config)

      expect(output).not_to include("Analyzers:")
    end
  end
end
