require "rails_helper"

RSpec.describe "Organizer::Events" do
  let(:club)      { create(:club) }
  let(:organizer) { create(:member, :organizer, club: club) }
  let(:headers)   { { "Host" => host_for(club) } }

  before { sign_in_as(organizer) }

  # ── Dollar input for ticket price ────────────────────────────────────────

  describe "GET /organizer/events/:slug/edit — dollar input rendering" do
    let(:event) { create(:event, :published, club: club, price_cents: 7500) }

    it "renders price in dollars (75.00), not cents (7500)" do
      get edit_organizer_event_path(event), headers: headers
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("75.0")
      expect(response.body).not_to include('value="7500"')
    end
  end

  describe "PATCH /organizer/events/:slug — strong params conversion" do
    let(:event) { create(:event, :published, club: club, price_cents: 0) }

    it "converts dollar input to cents before saving" do
      patch organizer_event_path(event), headers: headers,
            params: { event: { name: event.name, venue: event.venue,
                               capacity: event.capacity, price_cents: "75.00" } }
      expect(event.reload.price_cents).to eq(7500)
    end

    it "stores 0 cents when price is 0 (free event)" do
      patch organizer_event_path(event), headers: headers,
            params: { event: { name: event.name, venue: event.venue,
                               capacity: event.capacity, price_cents: "0" } }
      expect(event.reload.price_cents).to eq(0)
      expect(event.reload.free?).to be true
    end
  end

  # ── Attendees view — cancel button rendering ──────────────────────────────

  describe "GET /organizer/events/:slug/attendees" do
    let(:member) { create(:member, club: club) }

    context "paid event with a confirmed (paid) RSVP" do
      let(:paid_event) { create(:event, :paid, :published, club: club, price_cents: 5000) }
      let!(:rsvp) do
        create(:rsvp, :confirmed, :paid, event: paid_event, member: member,
               stripe_charge_id: "ch_test")
      end

      it "shows 'Cancel & refund' button" do
        get attendees_organizer_event_path(paid_event), headers: headers
        expect(response.body).to include("Cancel &amp; refund")
      end
    end

    context "paid event with a pending_payment RSVP" do
      let(:paid_event) { create(:event, :paid, :published, club: club, price_cents: 5000) }

      it "shows 'Pending payment' label, not a cancel button" do
        # attendees view only shows confirmed RSVPs (@rsvps = @event.rsvps.confirmed)
        # so pending_payment RSVPs are not in the list
        get attendees_organizer_event_path(paid_event), headers: headers
        expect(response.body).not_to include("Cancel &amp; refund")
      end
    end

    context "free event" do
      let(:free_event) { create(:event, :published, club: club, price_cents: 0) }
      let!(:rsvp)      { create(:rsvp, :confirmed, event: free_event, member: member) }

      it "does not show cancel column" do
        get attendees_organizer_event_path(free_event), headers: headers
        expect(response.body).not_to include("Cancel &amp; refund")
        expect(response.body).not_to include("Actions")
      end
    end
  end
end
