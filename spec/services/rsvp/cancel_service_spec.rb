require "rails_helper"

RSpec.describe Rsvp::CancelService do
  let(:club)      { create(:club, :with_stripe) }
  let(:member)    { create(:member, club: club) }

  describe "free event cancellation" do
    let(:event) { create(:event, :published, club: club, price_cents: 0) }
    let(:rsvp)  { create(:rsvp, :confirmed, event: event, member: member) }

    it "cancels without calling Stripe (member path)" do
      expect(Stripe::Refund).not_to receive(:create)
      described_class.call(rsvp: rsvp, by: :member)
      expect(rsvp.reload.cancelled?).to be true
    end

    it "cancels without calling Stripe (organizer path)" do
      expect(Stripe::Refund).not_to receive(:create)
      described_class.call(rsvp: rsvp, by: :organizer)
      expect(rsvp.reload.cancelled?).to be true
    end
  end

  describe "paid event — member cancellation" do
    let(:refund_cutoff) { 1.week.from_now }
    let(:event) do
      create(:event, :paid, :published, club: club,
             refund_cutoff_at: refund_cutoff, price_cents: 5000)
    end
    let(:rsvp) do
      create(:rsvp, :confirmed, :paid, event: event, member: member,
             stripe_charge_id: "ch_test_abc")
    end

    before { allow(Stripe::Refund).to receive(:create) }

    it "issues a Stripe refund and marks the RSVP cancelled before the cutoff" do
      described_class.call(rsvp: rsvp, by: :member)
      expect(Stripe::Refund).to have_received(:create).with(charge: "ch_test_abc")
      expect(rsvp.reload.cancelled?).to be true
      expect(rsvp.reload.refund_pending?).to be true
    end

    it "raises when paid_at is nil (guard: stripe_charge_id unreliable before webhook)" do
      rsvp.update!(paid_at: nil)
      expect {
        described_class.call(rsvp: rsvp, by: :member)
      }.to raise_error(/payment has not been confirmed/)
    end

    it "raises after refund_cutoff_at for :member path" do
      travel_to(refund_cutoff + 1.minute) do
        expect {
          described_class.call(rsvp: rsvp, by: :member)
        }.to raise_error(/refund cutoff/)
      end
    end
  end

  describe "paid event — organizer cancellation" do
    let(:past_cutoff) { 1.week.ago }
    let(:event) do
      create(:event, :paid, :published, club: club,
             refund_cutoff_at: past_cutoff, price_cents: 5000)
    end
    let(:rsvp) do
      create(:rsvp, :confirmed, :paid, event: event, member: member,
             stripe_charge_id: "ch_test_org")
    end

    before { allow(Stripe::Refund).to receive(:create) }

    it "bypasses refund_cutoff_at for :organizer path" do
      # cutoff is in the past, but organizer can still cancel
      expect { described_class.call(rsvp: rsvp, by: :organizer) }.not_to raise_error
      expect(Stripe::Refund).to have_received(:create)
      expect(rsvp.reload.cancelled?).to be true
    end

    it "still raises when paid_at is nil (guard applies to organizer too)" do
      rsvp.update!(paid_at: nil)
      expect {
        described_class.call(rsvp: rsvp, by: :organizer)
      }.to raise_error(/payment has not been confirmed/)
    end
  end
end
