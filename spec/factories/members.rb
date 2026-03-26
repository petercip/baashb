FactoryBot.define do
  factory :member do
    association :club
    sequence(:name)  { |n| "Member #{n}" }
    sequence(:email) { |n| "member#{n}@example.com" }
    password         { "password" }
    role             { :member }
    status           { :active }

    trait :organizer do
      role { :organizer }
    end

    trait :pending do
      status { :pending }
    end

    trait :removed do
      status { :removed }
    end

    # A member who signed up via Google and has no password
    trait :google_only do
      password  { nil }
      google_uid { SecureRandom.hex(10) }
    end
  end
end
