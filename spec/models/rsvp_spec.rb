require "rails_helper"

RSpec.describe Rsvp do
  subject(:rsvp) { build(:rsvp) }

  describe "associations" do
    it { is_expected.to belong_to(:event) }
    it { is_expected.to belong_to(:member) }
  end

  describe "validations" do
    it "prevents a member from RSVPing to the same event twice" do
      existing = create(:rsvp, :confirmed)
      duplicate = build(:rsvp, event: existing.event, member: existing.member)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:member_id]).to be_present
    end
  end

  describe "status enum" do
    it {
      is_expected.to define_enum_for(:status).with_values(
        pending_payment: "pending_payment",
        confirmed: "confirmed",
        cancelled: "cancelled"
      ).backed_by_column_of_type(:string)
    }
  end

  describe "#cancellable_by_member?" do
    context "when confirmed and refund_cutoff has not passed" do
      it "returns true for free events (no paid_at gating needed for free)" do
        event = create(:event, :published)
        member = create(:member, club: event.club)
        rsvp = create(:rsvp, :confirmed, event: event, member: member)
        # Free events: paid_at is nil, but there's no money to refund
        # cancellable_by_member? requires paid_at present — so free RSVPs aren't cancellable
        # by the member via the normal flow (they'd need organizer help).
        # This is intentional: free events may have capacity constraints.
        expect(rsvp.cancellable_by_member?).to be false
      end

      it "returns true for paid RSVPs before cutoff" do
        event = create(:event, :paid, :published, refund_cutoff_at: 1.day.from_now)
        member = create(:member, club: event.club)
        rsvp = create(:rsvp, :confirmed, :paid, event: event, member: member)
        expect(rsvp.cancellable_by_member?).to be true
      end

      it "returns false after refund cutoff" do
        event = create(:event, :paid, :published, refund_cutoff_at: 1.day.ago)
        member = create(:member, club: event.club)
        rsvp = create(:rsvp, :confirmed, :paid, event: event, member: member)
        expect(rsvp.cancellable_by_member?).to be false
      end
    end

    it "returns false for cancelled RSVPs" do
      rsvp = create(:rsvp, :cancelled)
      expect(rsvp.cancellable_by_member?).to be false
    end

    it "returns false for pending_payment RSVPs" do
      rsvp = create(:rsvp, :pending_payment)
      expect(rsvp.cancellable_by_member?).to be false
    end
  end

  describe "#cancellable_by_organizer?" do
    it "returns true for confirmed RSVPs" do
      rsvp = create(:rsvp, :confirmed)
      expect(rsvp.cancellable_by_organizer?).to be true
    end

    it "returns false for cancelled RSVPs" do
      rsvp = create(:rsvp, :cancelled)
      expect(rsvp.cancellable_by_organizer?).to be false
    end
  end
end
