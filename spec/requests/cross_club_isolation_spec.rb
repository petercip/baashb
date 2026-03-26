require "rails_helper"

# CRITICAL: Club A member must not be able to access Club B data.
# CLAUDE.md lists cross-club isolation as a must-pass test before any deploy.
RSpec.describe "Cross-club isolation" do
  let(:club_a)    { create(:club, slug: "club-a") }
  let(:club_b)    { create(:club, slug: "club-b") }
  let(:member_a)  { create(:member, :active, club: club_a) }
  let(:event_b)   { create(:event, :published, club: club_b) }
  let(:member_b)  { create(:member, :active, club: club_b) }

  # Headers that put the request in Club A's context
  let(:club_a_headers) { { "Host" => host_for(club_a) } }
  # Headers that put the request in Club B's context
  let(:club_b_headers) { { "Host" => host_for(club_b) } }

  before { sign_in_as(member_a) }

  describe "Event isolation" do
    it "Club A member cannot view Club B's event using Club A's host" do
      # Club B's event slug looked up via Club A's host — must 404
      get event_path(event_b.slug), headers: club_a_headers
      expect(response).to have_http_status(:not_found)
    end

    it "Club A member cannot RSVP to Club B's event via Club A's host" do
      expect {
        post rsvp_event_path(event_b.slug), headers: club_a_headers
      }.not_to change { Rsvp.count }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "Member isolation" do
    it "Club A member cannot view Club B's member profile via Club A's host" do
      get member_path(member_b.slug), headers: club_a_headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "Organizer isolation" do
    let(:organizer_a) { create(:member, :active, :organizer, club: club_a) }

    it "Club A organizer cannot view Club B's organizer event list" do
      sign_in_as(organizer_a)
      # Club B event with same slug as a Club A event
      same_slug_event = create(:event, :published, club: club_b, name: event_b.name)
      get organizer_event_path(same_slug_event.slug), headers: club_a_headers
      expect(response).to have_http_status(:not_found)
    end

    it "Club A organizer cannot view Club B's member list" do
      sign_in_as(organizer_a)
      get organizer_member_path(member_b.slug), headers: club_a_headers
      expect(response).to have_http_status(:not_found)
    end
  end
end
