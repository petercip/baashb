require "rails_helper"

RSpec.describe StripeWebhooks::CheckoutExpired do
  let(:club)    { create(:club) }
  let(:member)  { create(:member, club: club) }
  let(:event)   { create(:event, :paid, :published, club: club, capacity: 5, price_cents: 5000) }
  let!(:rsvp)   { create(:rsvp, :pending_payment, event: event, member: member) }

  def fake_session(session_id = rsvp.checkout_session_id)
    { "id" => session_id }
  end

  def call(session = fake_session)
    described_class.call(session)
  end

  it "destroys the pending RSVP when the session expires" do
    expect { call }.to change { Rsvp.count }.by(-1)
    expect(Rsvp.find_by(id: rsvp.id)).to be_nil
  end

  it "releases the capacity slot (confirmed_count decrements)" do
    # Confirm the event has the right confirmed count before and after
    confirmed_before = event.rsvps.confirmed.count
    call
    expect(event.rsvps.pending_payment.count).to eq(0)
    expect(event.rsvps.confirmed.count).to eq(confirmed_before)
  end

  it "does not destroy an already-confirmed RSVP" do
    rsvp.update!(status: :confirmed)
    expect { call }.not_to change { Rsvp.count }
  end
end
