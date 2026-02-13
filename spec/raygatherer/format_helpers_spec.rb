# frozen_string_literal: true

require_relative "../../lib/raygatherer/format_helpers"

RSpec.describe Raygatherer::FormatHelpers do
  include described_class

  it "returns '0 B' for nil" do
    expect(format_size(nil)).to eq("0 B")
  end

  it "formats bytes" do
    expect(format_size(512)).to eq("512 B")
  end

  it "formats kilobytes" do
    expect(format_size(2_048)).to eq("2.0 KB")
  end

  it "formats megabytes" do
    expect(format_size(47_513_600)).to eq("45.3 MB")
  end

  it "formats gigabytes" do
    expect(format_size(2_147_483_648)).to eq("2.0 GB")
  end

  it "uses boundary of 1024 for KB" do
    expect(format_size(1023)).to eq("1023 B")
    expect(format_size(1024)).to eq("1.0 KB")
  end
end
