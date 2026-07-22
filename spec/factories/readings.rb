FactoryBot.define do
  factory :reading do
    association :gauge, factory: :gauge
    association :entered_by, factory: :user
    period_start { gauge.periods.first.first }
    value { 100.0 }

    trait :approved do
      association :approved_by, factory: [ :user, :manager ]
      approved_at { Time.current }
    end
  end
end
