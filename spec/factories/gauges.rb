FactoryBot.define do
  factory :gauge do
    association :created_by, factory: :user
    sequence(:name) { |n| "Gauge #{n}" }
    starts_on { Date.new(2026, 1, 1) }
    ends_on   { Date.new(2026, 12, 31) }
    unit      { "kWh" }
    time_unit { :monthly }
  end
end
