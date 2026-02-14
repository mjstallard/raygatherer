# frozen_string_literal: true

RSpec.describe Raygatherer::Formatters::AnalysisStatusJSON do
  describe "#format" do
    it "outputs valid JSON" do
      status = {"queued" => [], "running" => nil, "finished" => []}

      output = described_class.new.format(status)

      expect { ::JSON.parse(output) }.not_to raise_error
    end

    it "preserves all fields" do
      status = {
        "queued" => ["rec1", "rec2"],
        "running" => "rec3",
        "finished" => ["rec4"]
      }

      output = described_class.new.format(status)

      parsed = ::JSON.parse(output)
      expect(parsed["queued"]).to eq(["rec1", "rec2"])
      expect(parsed["running"]).to eq("rec3")
      expect(parsed["finished"]).to eq(["rec4"])
    end
  end
end
