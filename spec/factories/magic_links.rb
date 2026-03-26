FactoryBot.define do
  factory :magic_link do
    association :member
    expires_at { MagicLink::ORGANIZER_INVITE_TTL.from_now }
    used_at    { nil }

    trait :expired do
      expires_at { 1.hour.ago }
    end

    trait :used do
      used_at { 1.hour.ago }
    end

    trait :self_signup do
      expires_at { MagicLink::SELF_SIGNUP_TTL.from_now }
    end
  end
end
