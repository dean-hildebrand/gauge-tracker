require "rails_helper"

RSpec.describe Gauge, type: :model do
  # `periods` is pure: it reads three attributes and touches no database, so we
  # build in memory with Gauge.new and never persist.
  def gauge(starts_on:, ends_on:, time_unit:)
    Gauge.new(starts_on: starts_on, ends_on: ends_on, time_unit: time_unit)
  end

  describe "#periods" do
    it "generates one period per month for a full calendar range" do
      periods = gauge(starts_on: Date.new(2026, 1, 1), ends_on: Date.new(2026, 12, 31), time_unit: :monthly).periods

      expect(periods.size).to eq(12)
      expect(periods.first).to eq(Date.new(2026, 1, 1)..Date.new(2026, 1, 31))
      expect(periods.last).to eq(Date.new(2026, 12, 1)..Date.new(2026, 12, 31))
    end

    it "truncates the first period when the range starts mid-month" do
      periods = gauge(starts_on: Date.new(2026, 3, 14), ends_on: Date.new(2026, 12, 31), time_unit: :monthly).periods

      expect(periods.first).to eq(Date.new(2026, 3, 14)..Date.new(2026, 3, 31))
      expect(periods.second).to eq(Date.new(2026, 4, 1)..Date.new(2026, 4, 30))
    end

    it "truncates the last period when the range ends mid-month" do
      periods = gauge(starts_on: Date.new(2026, 1, 1), ends_on: Date.new(2026, 6, 20), time_unit: :monthly).periods

      expect(periods.size).to eq(6)
      expect(periods.last).to eq(Date.new(2026, 6, 1)..Date.new(2026, 6, 20))
    end

    it "returns a single period truncated at both ends for a range shorter than one unit" do
      periods = gauge(starts_on: Date.new(2026, 3, 14), ends_on: Date.new(2026, 3, 20), time_unit: :monthly).periods

      expect(periods).to eq([ Date.new(2026, 3, 14)..Date.new(2026, 3, 20) ])
    end

    it "generates one single-date period per day for a daily gauge" do
      periods = gauge(starts_on: Date.new(2026, 1, 1), ends_on: Date.new(2026, 1, 5), time_unit: :daily).periods

      expect(periods.size).to eq(5)
      expect(periods).to all(satisfy { |range| range.first == range.last })
      expect(periods.first).to eq(Date.new(2026, 1, 1)..Date.new(2026, 1, 1))
    end

    it "generates one period per calendar year for a yearly gauge" do
      periods = gauge(starts_on: Date.new(2024, 1, 1), ends_on: Date.new(2026, 12, 31), time_unit: :yearly).periods

      expect(periods.size).to eq(3)
      expect(periods.first).to eq(Date.new(2024, 1, 1)..Date.new(2024, 12, 31))
      expect(periods.last).to eq(Date.new(2026, 1, 1)..Date.new(2026, 12, 31))
    end

    it "returns an empty array when dates are missing" do
      expect(gauge(starts_on: nil, ends_on: nil, time_unit: :monthly).periods).to eq([])
    end

    it "returns an empty array when the range is inverted" do
      expect(gauge(starts_on: Date.new(2026, 12, 31), ends_on: Date.new(2026, 1, 1), time_unit: :monthly).periods).to eq([])
    end
  end

  describe "validations" do
    it "requires a name" do
      expect(build(:gauge, name: nil)).not_to be_valid
    end

    it "rejects a name longer than 120 characters" do
      expect(build(:gauge, name: "a" * 121)).not_to be_valid
    end

    it "requires a unit" do
      expect(build(:gauge, unit: nil)).not_to be_valid
    end

    it "requires start and end dates" do
      expect(build(:gauge, starts_on: nil)).not_to be_valid
      expect(build(:gauge, ends_on: nil)).not_to be_valid
    end

    it "rejects an end date on or before the start date" do
      expect(build(:gauge, starts_on: Date.new(2026, 6, 1), ends_on: Date.new(2026, 6, 1))).not_to be_valid
      expect(build(:gauge, starts_on: Date.new(2026, 6, 1), ends_on: Date.new(2026, 5, 1))).not_to be_valid
    end
  end
end
