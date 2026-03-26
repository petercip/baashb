FactoryBot.define do
  factory :announcement do
    association :club
    association :author, factory: :member
    sequence(:subject) { |n| "Announcement #{n}" }
    body               { "This is the announcement body." }
    recipient_scope    { "all_members" }

    trait :sent do
      sent_at          { 1.hour.ago }
      recipient_count  { 10 }
    end

    trait :for_event do
      recipient_scope  { "event_attendees" }
      association :target_event, factory: :event
    end
  end
end
