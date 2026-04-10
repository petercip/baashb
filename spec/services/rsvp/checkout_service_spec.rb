require "rails_helper"

RSpec.describe Rsvp::CheckoutService do
  let(:club)   { create(:club, :with_stripe) }
  let(:member) { create(:member, club: club) }
  let(:event)  { create(:event, :paid, :published, club: club, capacity: 10, price_cents: 5000) }

  let(:success_url) { "https://example.com/checkout/return?slug=#{event.slug}" }
  let(:cancel_url)  { "https://example.com/events/#{event.slug}" }

  let(:fake_session) do
    double("Stripe::Checkout::Session",
           id:  "cs_test_abc123",
           url: "https://checkout.stripe.com/pay/cs_test_abc123")
  end

  before do
    allow(Stripe::Checkout::Session).to receive(:create).and_return(fake_session)
  end

  def call(donation_cents: 0)
    described_class.call(
      event:          event,
      member:         member,
      donation_cents: donation_cents,
      success_url:    success_url,
      cancel_url:     cancel_url
    )
  end

  it "returns a checkout_url on success" do
    result = call
    expect(result[:checkout_url]).to eq("https://checkout.stripe.com/pay/cs_test_abc123")
    expect(result[:error]).to be_nil
  end

  it "creates a pending_payment RSVP" do
    expect { call }.to change { event.rsvps.pending_payment.count }.by(1)
  end

  it "stores checkout_session_id on the RSVP" do
    call
    rsvp = event.rsvps.pending_payment.last
    expect(rsvp.checkout_session_id).to eq("cs_test_abc123")
  end

  it "passes expires_at 30 minutes from now to Stripe" do
    freeze_time do
      call
      expect(Stripe::Checkout::Session).to have_received(:create).with(
        hash_including(expires_at: 30.minutes.from_now.to_i)
      )
    end
  end

  it "passes expand: payment_intent.latest_charge to Stripe" do
    call
    expect(Stripe::Checkout::Session).to have_received(:create).with(
      hash_including(expand: [ "payment_intent.latest_charge" ])
    )
  end

  context "with donation_cents: 0" do
    it "creates a Stripe session with exactly one line item" do
      call(donation_cents: 0)
      expect(Stripe::Checkout::Session).to have_received(:create).with(
        hash_including(line_items: have_attributes(size: 1))
      )
    end
  end

  context "with donation_cents: 1000" do
    it "creates a Stripe session with two line items (ticket + donation)" do
      call(donation_cents: 1000)
      expect(Stripe::Checkout::Session).to have_received(:create).with(
        hash_including(line_items: have_attributes(size: 2))
      )
    end

    it "stores donation_amount_cents on the pending RSVP" do
      call(donation_cents: 1000)
      rsvp = event.rsvps.pending_payment.last
      expect(rsvp.donation_amount_cents).to eq(1000)
    end
  end

  context "when Stripe raises a StripeError" do
    before do
      allow(Stripe::Checkout::Session).to receive(:create)
        .and_raise(Stripe::StripeError, "card_error")
    end

    it "returns an error hash instead of raising" do
      result = call
      expect(result[:error]).to be_present
      expect(result[:checkout_url]).to be_nil
    end
  end

  context "when event is at capacity" do
    let(:event) { create(:event, :paid, :published, club: club, capacity: 1, price_cents: 5000) }

    before do
      other_member = create(:member, club: club)
      create(:rsvp, :confirmed, event: event, member: other_member)
    end

    it "returns an error without creating a Stripe session" do
      result = call
      expect(result[:error]).to be_present
      expect(Stripe::Checkout::Session).not_to have_received(:create)
    end
  end

  context "success_url and cancel_url are passed in (not generated inside service)" do
    it "passes the provided success_url to Stripe" do
      call
      expect(Stripe::Checkout::Session).to have_received(:create).with(
        hash_including(success_url: success_url, cancel_url: cancel_url)
      )
    end
  end

  context "when member has a cancelled RSVP (reactivation)" do
    before do
      create(:rsvp, :cancelled, event: event, member: member,
             paid_at: nil, amount_paid_cents: nil, stripe_charge_id: nil)
    end

    it "reactivates the existing RSVP as pending_payment" do
      expect { call }.not_to change { Rsvp.count }
      rsvp = event.rsvps.find_by(member: member)
      expect(rsvp.pending_payment?).to be true
    end

    it "resets payment fields on reactivation" do
      call
      rsvp = event.rsvps.find_by(member: member)
      expect(rsvp.paid_at).to be_nil
      expect(rsvp.amount_paid_cents).to be_nil
      expect(rsvp.stripe_charge_id).to be_nil
      expect(rsvp.refund_status).to be_nil
    end
  end
end
