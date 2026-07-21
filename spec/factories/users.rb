FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password" }
    name { "Test User" }
    role { :employee }

    trait :employee do
      role { :employee }
    end

    trait :manager do
      role { :manager }
    end
  end
end
