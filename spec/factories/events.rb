FactoryBot.define do
  factory :event do
    association :club
    sequence(:name) { |n| "Event #{n}" }
    description     { "A test event description." }
    starts_at       { 2.weeks.from_now }
    ends_at         { 2.weeks.from_now + 3.hours }
    venue           { "Test Venue, San Francisco" }
    capacity        { 50 }
    price_cents     { 0 }
    status          { :published }

    trait :draft do
      status { :draft }
    end

    trait :published do
      status { :published }
    end

    trait :cancelled do
      status      { :cancelled }
      cancelled_at { 1.day.ago }
    end

    trait :paid do
      price_cents { 5000 }  # $50.00
    end

    trait :past do
      starts_at { 1.month.ago }
      ends_at   { 1.month.ago + 3.hours }
    end

    trait :full do
      capacity { 1 }
      after(:create) do |event|
        member = create(:member, club: event.club)
        create(:rsvp, :confirmed, event: event, member: member)
      end
    end
  end
end
