FactoryBot.define do
  factory :club do
    sequence(:name)          { |n| "Test Club #{n}" }
    sequence(:slug)          { |n| "testclub#{n}" }
    sequence(:contact_email) { |n| "contact#{n}@example.com" }
    primary_color            { "#c8a96e" }
    font_choice              { "Inter" }
    ssl_status               { :pending }

    trait :with_custom_domain do
      sequence(:custom_domain) { |n| "club#{n}.example.org" }
    end

    trait :with_stripe do
      stripe_secret_key      { "sk_test_example" }
      stripe_publishable_key { "pk_test_example" }
      stripe_webhook_secret  { "whsec_example" }
    end
  end
end
