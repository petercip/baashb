require "rails_helper"

RSpec.describe Announcement do
  let(:club)   { create(:club) }
  let(:author) { create(:member, club: club) }

  subject(:announcement) do
    build(:announcement, club: club, author: author)
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:subject) }
    it { is_expected.to validate_presence_of(:body) }

    describe "recipient_scope" do
      it "accepts 'all_members'" do
        announcement.recipient_scope = "all_members"
        expect(announcement).to be_valid
      end

      it "accepts 'event_attendees' when target_event is set and belongs to the club" do
        event = create(:event, club: club)
        announcement.recipient_scope = "event_attendees"
        announcement.target_event = event
        expect(announcement).to be_valid
      end

      it "rejects an unknown scope" do
        announcement.recipient_scope = "nobody"
        expect(announcement).not_to be_valid
        expect(announcement.errors[:recipient_scope]).to be_present
      end

      it "requires target_event when scope is 'event_attendees'" do
        announcement.recipient_scope = "event_attendees"
        announcement.target_event = nil
        expect(announcement).not_to be_valid
        expect(announcement.errors[:target_event]).to be_present
      end
    end

    describe "target_event cross-club guard" do
      let(:other_club) { create(:club, slug: "other-club") }
      let(:other_event) { create(:event, club: other_club) }

      it "rejects a target_event that belongs to a different club" do
        announcement.recipient_scope = "event_attendees"
        announcement.target_event = other_event
        expect(announcement).not_to be_valid
        expect(announcement.errors[:target_event]).to include("must belong to the same club")
      end

      it "accepts a target_event that belongs to the same club" do
        event = create(:event, club: club)
        announcement.recipient_scope = "event_attendees"
        announcement.target_event = event
        expect(announcement).to be_valid
      end
    end
  end

  describe "#sent?" do
    it "returns false when sent_at is nil" do
      announcement.sent_at = nil
      expect(announcement.sent?).to be false
    end

    it "returns true when sent_at is set" do
      announcement.sent_at = Time.current
      expect(announcement.sent?).to be true
    end
  end

  describe "scopes" do
    let!(:sent_announcement)  { create(:announcement, :sent, club: club, author: author) }
    let!(:draft_announcement) { create(:announcement, club: club, author: author) }

    it ".sent returns announcements with a sent_at" do
      expect(Announcement.sent).to include(sent_announcement)
      expect(Announcement.sent).not_to include(draft_announcement)
    end

    it ".drafts returns announcements without a sent_at" do
      expect(Announcement.drafts).to include(draft_announcement)
      expect(Announcement.drafts).not_to include(sent_announcement)
    end
  end
end
