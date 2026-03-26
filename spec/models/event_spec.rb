require "rails_helper"

RSpec.describe Event do
  subject(:event) { build(:event) }

  describe "associations" do
    it { is_expected.to belong_to(:club) }
    it { is_expected.to have_many(:rsvps) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:starts_at) }
    it { is_expected.to validate_presence_of(:venue) }
  end

  describe "slug" do
    it "generates a slug from the name on create" do
      event = create(:event, name: "Spring Rowing Dinner")
      expect(event.slug).to eq("spring-rowing-dinner")
    end

    it "does not regenerate the slug when the name changes" do
      event = create(:event, name: "Spring Rowing Dinner")
      original_slug = event.slug
      event.update!(name: "Renamed Event")
      expect(event.reload.slug).to eq(original_slug)
    end

    it "scopes slugs to the club (two clubs can have the same event name)" do
      club_a = create(:club)
      club_b = create(:club)
      event_a = create(:event, club: club_a, name: "Annual Dinner")
      event_b = create(:event, club: club_b, name: "Annual Dinner")
      expect(event_a.slug).to eq(event_b.slug)  # same slug is OK across clubs
    end
  end

  describe "status enum" do
    it { is_expected.to define_enum_for(:status).with_values(draft: "draft", published: "published", cancelled: "cancelled").backed_by_column_of_type(:string) }
  end

  describe "#free?" do
    it "returns true when price_cents is 0" do
      event.price_cents = 0
      expect(event.free?).to be true
    end

    it "returns false when price_cents is greater than 0" do
      event.price_cents = 5000
      expect(event.free?).to be false
    end
  end

  describe "#confirmed_count" do
    it "counts only confirmed rsvps" do
      event = create(:event)
      create(:rsvp, :confirmed, event: event, member: create(:member, club: event.club))
      create(:rsvp, :confirmed, event: event, member: create(:member, club: event.club))
      create(:rsvp, :pending_payment, event: event, member: create(:member, club: event.club))
      create(:rsvp, :cancelled, event: event, member: create(:member, club: event.club))
      expect(event.confirmed_count).to eq(2)
    end
  end

  describe "#spots_remaining" do
    it "returns capacity minus confirmed count" do
      event = create(:event, capacity: 10)
      2.times { create(:rsvp, :confirmed, event: event, member: create(:member, club: event.club)) }
      expect(event.spots_remaining).to eq(8)
    end
  end

  describe "#full?" do
    it "returns false when spots remain" do
      event = create(:event, capacity: 10)
      expect(event.full?).to be false
    end

    it "returns true when confirmed RSVPs equal capacity" do
      event = create(:event, capacity: 1)
      create(:rsvp, :confirmed, event: event, member: create(:member, club: event.club))
      expect(event.full?).to be true
    end
  end

  describe "#fomo_level" do
    let(:event) { create(:event, capacity: 100) }

    it "returns :none when < 50% full" do
      expect(event.fomo_level).to eq(:none)
    end

    it "returns :neutral when 50-79% full" do
      60.times { create(:rsvp, :confirmed, event: event, member: create(:member, club: event.club)) }
      expect(event.fomo_level).to eq(:neutral)
    end

    it "returns :warning when 80-99% full" do
      85.times { create(:rsvp, :confirmed, event: event, member: create(:member, club: event.club)) }
      expect(event.fomo_level).to eq(:warning)
    end

    it "returns :soldout when 100% full" do
      100.times { create(:rsvp, :confirmed, event: event, member: create(:member, club: event.club)) }
      expect(event.fomo_level).to eq(:soldout)
    end
  end

  describe "#fomo_label" do
    it "returns nil-ish for :none level" do
      event = create(:event, capacity: 100)
      expect(event.fomo_label).to be_nil
    end

    it "returns a spots message for :neutral" do
      event = create(:event, capacity: 100)
      60.times { create(:rsvp, :confirmed, event: event, member: create(:member, club: event.club)) }
      expect(event.fomo_label).to include("40")
    end

    it "returns 'Sold out' for :soldout" do
      event = create(:event, capacity: 1)
      create(:rsvp, :confirmed, event: event, member: create(:member, club: event.club))
      expect(event.fomo_label).to eq("Sold out")
    end
  end

  describe "scopes" do
    it ".upcoming returns events starting in the future" do
      future = create(:event, starts_at: 1.week.from_now)
      past   = create(:event, :past)
      expect(Event.upcoming).to include(future)
      expect(Event.upcoming).not_to include(past)
    end

    it ".past returns events starting in the past" do
      future = create(:event, starts_at: 1.week.from_now)
      past   = create(:event, :past)
      expect(Event.past).to include(past)
      expect(Event.past).not_to include(future)
    end

    it ".published excludes drafts and cancelled events" do
      published  = create(:event, :published)
      draft      = create(:event, :draft)
      cancelled  = create(:event, :cancelled)
      expect(Event.published).to include(published)
      expect(Event.published).not_to include(draft, cancelled)
    end
  end
end
