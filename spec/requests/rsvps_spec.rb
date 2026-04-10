require "rails_helper"

RSpec.describe "Rsvps" do
  let(:club)    { create(:club, :with_stripe) }
  let(:member)  { create(:member, club: club) }
  let(:headers) { { "Host" => host_for(club) } }

  let(:free_event) do
    create(:event, :published, club: club, price_cents: 0, capacity: 10)
  end

  let(:paid_event) do
    create(:event, :paid, :published, club: club, price_cents: 5000, capacity: 10)
  end

  let(:fake_checkout_url) { "https://checkout.stripe.com/pay/cs_test_abc" }

  before do
    allow(Rsvp::CheckoutService).to receive(:call)
      .and_return({ checkout_url: fake_checkout_url })
  end

  # ── RsvpsController#new — pre-checkout donation form ─────────────────────

  describe "GET /events/:slug/rsvp (donation form)" do
    context "when authenticated" do
      before { sign_in_as(member) }

      it "returns 200 for a paid event" do
        get new_rsvp_event_path(paid_event), headers: headers
        expect(response).to have_http_status(:ok)
      end

      it "redirects to event page for a free event" do
        get new_rsvp_event_path(free_event), headers: headers
        expect(response).to redirect_to(event_path(free_event))
      end
    end

    context "when unauthenticated" do
      it "redirects to sign-in" do
        get new_rsvp_event_path(paid_event), headers: headers
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  # ── RsvpsController#create — paid event path ─────────────────────────────

  describe "POST /events/:slug/rsvps (paid event)" do
    before { sign_in_as(member) }

    it "with donation_cents: 0 → creates pending RSVP and redirects to Stripe" do
      post rsvp_event_path(paid_event), headers: headers,
           params: { donation_cents: 0 }
      expect(response).to redirect_to(fake_checkout_url)
      expect(Rsvp::CheckoutService).to have_received(:call).with(
        hash_including(donation_cents: 0)
      )
    end

    it "with donation_cents: 1000 → calls CheckoutService with donation amount" do
      post rsvp_event_path(paid_event), headers: headers,
           params: { donation_cents: 1000 }
      expect(Rsvp::CheckoutService).to have_received(:call).with(
        hash_including(donation_cents: 1000)
      )
    end

    it "when event is at capacity → redirects to event page with sold out message" do
      allow(Rsvp::CheckoutService).to receive(:call)
        .and_return({ error: "Sorry — this event is sold out." })
      post rsvp_event_path(paid_event), headers: headers,
           params: { donation_cents: 0 }
      expect(response).to redirect_to(event_path(paid_event))
      expect(flash[:alert]).to include("sold out")
    end

    context "when member already has a confirmed RSVP" do
      before { create(:rsvp, :confirmed, event: paid_event, member: member) }

      it "returns an error from CheckoutService" do
        allow(Rsvp::CheckoutService).to receive(:call)
          .and_return({ error: "You are already attending this event." })
        post rsvp_event_path(paid_event), headers: headers,
             params: { donation_cents: 0 }
        expect(response).to redirect_to(event_path(paid_event))
      end
    end

    context "when member has a pending_payment RSVP" do
      before { create(:rsvp, :pending_payment, event: paid_event, member: member) }

      it "returns an error from CheckoutService" do
        allow(Rsvp::CheckoutService).to receive(:call)
          .and_return({ error: "You already have a pending checkout for this event." })
        post rsvp_event_path(paid_event), headers: headers,
             params: { donation_cents: 0 }
        expect(response).to redirect_to(event_path(paid_event))
      end
    end

    context "when member has a cancelled RSVP (reactivation)" do
      before { create(:rsvp, :cancelled, event: paid_event, member: member) }

      it "redirects to Stripe for checkout (CheckoutService handles reactivation)" do
        post rsvp_event_path(paid_event), headers: headers,
             params: { donation_cents: 0 }
        expect(response).to redirect_to(fake_checkout_url)
      end
    end

    context "when CheckoutService returns an error" do
      before do
        allow(Rsvp::CheckoutService).to receive(:call)
          .and_return({ error: "Stripe error occurred." })
      end

      it "redirects to the event page with an alert" do
        post rsvp_event_path(paid_event), headers: headers,
             params: { donation_cents: 0 }
        expect(response).to redirect_to(event_path(paid_event))
      end
    end
  end
end
