FactoryBot.define do
  factory :session do
    association :member
    expires_at { Session::SESSION_TTL.from_now }
  end
end
