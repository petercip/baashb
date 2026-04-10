require "rails_helper"

RSpec.describe "Events" do
  let(:club)   { create(:club) }
  let(:member) { create(:member, club: club) }
  let!(:published_event) { create(:event, :published, club: club, starts_at: 1.week.from_now) }
  let!(:past_event)      { create(:event, :published, :past, club: club) }
  let!(:draft_event)     { create(:event, :draft, club: club) }

  let(:headers) { { "Host" => host_for(club) } }

  describe "GET /events (auth-gated members-only list)" do
    context "when not signed in" do
      it "redirects to sign-in" do
        get events_path, headers: headers
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when signed in" do
      before { sign_in_as(member) }

      it "returns 200 and shows upcoming events" do
        get events_path, headers: headers
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(published_event.name)
      end

      it "does not show draft events" do
        get events_path, headers: headers
        expect(response.body).not_to include(draft_event.name)
      end
    end
  end

  describe "GET /events/:slug (public shareable page)" do
    it "returns 200 for a published event without sign-in" do
      get event_path(published_event), headers: headers
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(published_event.name)
    end

    it "returns 404 for a slug that doesn't exist" do
      get event_path("nonexistent-event"), headers: headers
      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for a draft event (drafts are not publicly accessible)" do
      get event_path(draft_event), headers: headers
      expect(response).to have_http_status(:not_found)
    end

    it "shows RSVP button for signed-in member with no RSVP" do
      sign_in_as(member)
      get event_path(published_event), headers: headers
      expect(response.body).to include("RSVP")
    end

    it "shows 'Attending' for a confirmed attendee" do
      create(:rsvp, :confirmed, event: published_event, member: member)
      sign_in_as(member)
      get event_path(published_event), headers: headers
      expect(response.body).to include("Attending")
    end
  end

  describe "POST /events/:slug/rsvps (free event)" do
    context "when signed in" do
      before { sign_in_as(member) }

      it "creates a confirmed RSVP and redirects back to the event" do
        expect {
          post rsvp_event_path(published_event), headers: headers
        }.to change { published_event.rsvps.confirmed.count }.by(1)

        expect(response).to redirect_to(event_path(published_event))
      end

      it "prevents duplicate RSVPs" do
        create(:rsvp, :confirmed, event: published_event, member: member)
        expect {
          post rsvp_event_path(published_event), headers: headers
        }.not_to change { Rsvp.count }

        expect(response).to redirect_to(event_path(published_event))
        expect(flash[:notice]).to include("already")
      end

      it "prevents RSVP to a full event" do
        other_member = create(:member, club: club)
        published_event.update!(capacity: 1)
        create(:rsvp, :confirmed, event: published_event, member: other_member)

        expect {
          post rsvp_event_path(published_event), headers: headers
        }.not_to change { Rsvp.count }

        expect(response).to redirect_to(event_path(published_event))
        expect(flash[:alert]).to include("sold out")
      end

      it "allows re-RSVP after cancellation by reactivating the existing record" do
        # Establish a cancelled RSVP (simulates a member who previously cancelled)
        cancelled_rsvp = create(:rsvp, :cancelled, event: published_event, member: member)

        expect {
          post rsvp_event_path(published_event), headers: headers
        }.not_to change { Rsvp.count }  # no new record — existing one is reactivated

        expect(response).to redirect_to(event_path(published_event))
        expect(cancelled_rsvp.reload.status).to eq("confirmed")
        expect(cancelled_rsvp.reload.cancelled_at).to be_nil
      end
    end

    context "when not signed in" do
      it "redirects to sign in" do
        post rsvp_event_path(published_event), headers: headers
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  # ── Event show — free/paid/sold-out RSVP branch ──────────────────────────

  describe "GET /events/:slug — RSVP action branch" do
    let(:paid_event) { create(:event, :paid, :published, club: club, price_cents: 5000) }

    before { sign_in_as(member) }

    it "renders a POST form RSVP button for a free event" do
      get event_path(published_event), headers: headers
      expect(response.body).to include('method="post"')
      expect(response.body).to include("RSVP")
    end

    it "renders a link to the donation form for a paid event" do
      get event_path(paid_event), headers: headers
      expect(response.body).to include(new_rsvp_event_path(paid_event))
      expect(response.body).to include("Get tickets")
    end

    it "renders 'Sold out' badge and no RSVP action for a full event" do
      full_event = create(:event, :published, club: club, capacity: 1)
      other_member = create(:member, club: club)
      create(:rsvp, :confirmed, event: full_event, member: other_member)

      get event_path(full_event), headers: headers
      expect(response.body).to include("Sold out")
      expect(response.body).not_to include("RSVP")
    end
  end
end
