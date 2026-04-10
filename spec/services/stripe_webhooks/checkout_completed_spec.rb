require "rails_helper"

RSpec.describe StripeWebhooks::CheckoutCompleted do
  let(:club)   { create(:club) }
  let(:member) { create(:member, club: club) }
  let(:event)  { create(:event, :paid, :published, club: club, price_cents: 5000) }
  let!(:rsvp)  { create(:rsvp, :pending_payment, event: event, member: member) }

  let(:charge_id) { "ch_test_abc123" }

  def fake_session(overrides = {})
    {
      "id"           => rsvp.checkout_session_id,
      "amount_total" => 5000,
      "payment_intent" => {
        "latest_charge" => {
          "id" => charge_id
        }
      },
      "metadata" => { "rsvp_id" => rsvp.id.to_s }
    }.merge(overrides)
  end

  def call(session = fake_session)
    described_class.call(session)
  end

  it "transitions RSVP from pending_payment to confirmed" do
    call
    expect(rsvp.reload.confirmed?).to be true
  end

  it "sets paid_at, amount_paid_cents, and stripe_charge_id" do
    freeze_time do
      call
      rsvp.reload
      expect(rsvp.paid_at).to be_within(1.second).of(Time.current)
      expect(rsvp.amount_paid_cents).to eq(5000)
      expect(rsvp.stripe_charge_id).to eq(charge_id)
    end
  end

  it "queues paid_event_confirmation email" do
    expect(RsvpConfirmationMailer).to receive(:paid_event_confirmation)
      .with(rsvp)
      .and_return(double(deliver_later: true))
    call
  end

  describe "idempotency" do
    it "does not confirm or re-send email if RSVP is already confirmed" do
      rsvp.update!(status: :confirmed, paid_at: 1.hour.ago)
      expect(RsvpConfirmationMailer).not_to receive(:paid_event_confirmation)
      call
    end
  end

  describe "fallback lookup via metadata[:rsvp_id]" do
    it "finds the RSVP via metadata when checkout_session_id lookup returns nil" do
      # Simulate a timing edge: no RSVP matches checkout_session_id
      rsvp.update!(checkout_session_id: "cs_other")
      session = fake_session("id" => "cs_unknown")

      call(session)
      expect(rsvp.reload.confirmed?).to be true
    end
  end

  describe "cross-club isolation" do
    it "does not confirm an RSVP belonging to a different club" do
      other_club   = create(:club)
      other_member = create(:member, club: other_club)
      other_event  = create(:event, :paid, :published, club: other_club)
      other_rsvp   = create(:rsvp, :pending_payment, event: other_event, member: other_member,
                             checkout_session_id: "cs_other_club")

      # Webhook with other club's session ID — our RSVP has a different session ID
      session = fake_session("id" => "cs_other_club",
                             "metadata" => { "rsvp_id" => other_rsvp.id.to_s })

      # Our RSVP should remain unchanged
      expect { call(session) }.not_to change { rsvp.reload.status }
    end
  end
end
