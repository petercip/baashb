require "rails_helper"

RSpec.describe StripeWebhooks::ChargeRefunded do
  let(:club)    { create(:club) }
  let(:member)  { create(:member, club: club) }
  let(:event)   { create(:event, :paid, :published, club: club) }
  let!(:rsvp)   do
    create(:rsvp, :confirmed, :paid, event: event, member: member,
           stripe_charge_id: "ch_test_refund_abc",
           status: :cancelled, cancelled_at: 1.hour.ago,
           refund_status: "pending")
  end

  let(:refund_id) { "re_test_123" }

  def fake_charge(charge_id = "ch_test_refund_abc")
    {
      "id"      => charge_id,
      "refunds" => {
        "data" => [{ "id" => refund_id, "status" => "succeeded" }]
      }
    }
  end

  def call(charge = fake_charge)
    described_class.call(charge)
  end

  it "sets refund_status to refund_succeeded and stores stripe_refund_id" do
    freeze_time do
      call
      rsvp.reload
      expect(rsvp.refund_succeeded?).to be true
      expect(rsvp.stripe_refund_id).to eq(refund_id)
      expect(rsvp.refunded_at).to be_within(1.second).of(Time.current)
    end
  end

  describe "idempotency" do
    it "does not double-update if already refund_succeeded" do
      rsvp.update!(refund_status: :refund_succeeded, stripe_refund_id: refund_id)
      original_updated_at = rsvp.updated_at

      travel_to(1.minute.from_now) { call }

      expect(rsvp.reload.updated_at).to be_within(1.second).of(original_updated_at)
    end
  end

  describe "nil guard" do
    it "returns without raising when stripe_charge_id is not found" do
      expect { call(fake_charge("ch_unknown")) }.not_to raise_error
    end
  end
end
