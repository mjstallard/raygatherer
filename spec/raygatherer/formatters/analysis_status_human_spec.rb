# frozen_string_literal: true

RSpec.describe Raygatherer::Formatters::AnalysisStatusHuman do
  describe "#format" do
    it "shows running recording" do
      status = {"queued" => [], "running" => "rec1", "finished" => []}

      output = described_class.new.format(status)

      expect(output).to include("Running: rec1")
    end

    it "shows (none) when nothing is running" do
      status = {"queued" => [], "running" => nil, "finished" => []}

      output = described_class.new.format(status)

      expect(output).to include("Running: (none)")
    end

    it "shows queued recordings" do
      status = {"queued" => ["rec1", "rec2"], "running" => nil, "finished" => []}

      output = described_class.new.format(status)

      expect(output).to include("Queued (2):")
      expect(output).to include("  rec1")
      expect(output).to include("  rec2")
    end

    it "shows (none) when queue is empty" do
      status = {"queued" => [], "running" => nil, "finished" => []}

      output = described_class.new.format(status)

      expect(output).to include("Queued (0):")
      expect(output).to include("  (none)")
    end

    it "shows finished recordings" do
      status = {"queued" => [], "running" => nil, "finished" => ["rec3", "rec4"]}

      output = described_class.new.format(status)

      expect(output).to include("Finished (2):")
      expect(output).to include("  rec3")
      expect(output).to include("  rec4")
    end

    it "shows (none) when finished is empty" do
      status = {"queued" => [], "running" => nil, "finished" => []}

      output = described_class.new.format(status)

      expect(output).to include("Finished (0):")
    end

    it "shows full status with all sections" do
      status = {
        "queued" => ["q1"],
        "running" => "r1",
        "finished" => ["f1", "f2"]
      }

      output = described_class.new.format(status)

      expect(output).to include("Running: r1")
      expect(output).to include("Queued (1):")
      expect(output).to include("Finished (2):")
    end
  end
end
