# frozen_string_literal: true

RSpec.describe Raygatherer::Formatters::UpdateStatusHuman do
  describe "#format" do
    let(:full_status) do
      {
        "current_version" => "0.12.0",
        "update_available" => true,
        "latest_version" => "0.13.0",
        "latest_release_url" => "https://github.com/EFForg/rayhunter/releases/tag/v0.13.0",
        "last_checked" => "2026-09-01T12:00:00+00:00"
      }
    end

    it "shows current version" do
      output = described_class.new.format(full_status)

      expect(output).to include("Current version: 0.12.0")
    end

    it "shows update available as yes" do
      output = described_class.new.format(full_status)

      expect(output).to include("Update available: yes")
    end

    it "shows update available as no" do
      status = full_status.merge("update_available" => false)

      output = described_class.new.format(status)

      expect(output).to include("Update available: no")
    end

    it "shows latest version when present" do
      output = described_class.new.format(full_status)

      expect(output).to include("Latest version: 0.13.0")
    end

    it "omits latest version when not present" do
      status = full_status.except("latest_version")

      output = described_class.new.format(status)

      expect(output).not_to include("Latest version")
    end

    it "shows release notes URL when present" do
      output = described_class.new.format(full_status)

      expect(output).to include("Release notes: https://github.com/EFForg/rayhunter/releases/tag/v0.13.0")
    end

    it "omits release notes when not present" do
      status = full_status.except("latest_release_url")

      output = described_class.new.format(status)

      expect(output).not_to include("Release notes")
    end

    it "shows last checked when present" do
      output = described_class.new.format(full_status)

      expect(output).to include("Last checked: 2026-09-01T12:00:00+00:00")
    end

    it "omits last checked when not present" do
      status = full_status.except("last_checked")

      output = described_class.new.format(status)

      expect(output).not_to include("Last checked")
    end

    it "shows last error when present" do
      status = full_status.merge("last_error" => "connection timed out")

      output = described_class.new.format(status)

      expect(output).to include("Last error: connection timed out")
    end

    it "omits last error when not present" do
      output = described_class.new.format(full_status)

      expect(output).not_to include("Last error")
    end

    it "notes that no update check has run yet when latest_version and last_checked are both absent" do
      status = {"current_version" => "0.12.0", "update_available" => false}

      output = described_class.new.format(status)

      expect(output).to include("No update check has run yet")
    end

    it "does not show the no-check note when a check has run" do
      output = described_class.new.format(full_status)

      expect(output).not_to include("No update check has run yet")
    end
  end
end
