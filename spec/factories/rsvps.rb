FactoryBot.define do
  factory :rsvp do
    association :event
    association :member

    status { :confirmed }

    trait :confirmed do
      status { :confirmed }
    end

    trait :pending_payment do
      status                { :pending_payment }
      sequence(:checkout_session_id) { |n| "cs_test_#{n}" }
    end

    trait :cancelled do
      status       { :cancelled }
      cancelled_at { 1.hour.ago }
    end

    trait :paid do
      amount_paid_cents { 5000 }
      paid_at           { 1.hour.ago }
    end
  end
end
