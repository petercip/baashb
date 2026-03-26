require "rails_helper"

# Verifies that Organizer::BaseController's require_organizer! gate works
# end-to-end: a plain member must be rejected from every organizer route.
RSpec.describe "Organizer access control" do
  let(:club)      { create(:club) }
  let(:member)    { create(:member, :active, club: club) }
  let(:organizer) { create(:member, :active, :organizer, club: club) }
  let(:headers)   { { "Host" => host_for(club) } }

  shared_examples "requires organizer role" do
    it "redirects a plain member to root with an alert" do
      sign_in_as(member)
      get path, headers: headers
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to be_present
    end

    it "redirects an unauthenticated visitor to sign-in" do
      get path, headers: headers
      expect(response).to redirect_to(new_session_path)
    end
  end

  describe "GET /organizer" do
    let(:path) { organizer_root_path }

    include_examples "requires organizer role"

    it "allows an organizer" do
      sign_in_as(organizer)
      get organizer_root_path, headers: headers
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /organizer/events" do
    let(:path) { organizer_events_path }
    include_examples "requires organizer role"
  end

  describe "GET /organizer/members" do
    let(:path) { organizer_members_path }
    include_examples "requires organizer role"
  end

  describe "GET /organizer/announcements" do
    let(:path) { organizer_announcements_path }
    include_examples "requires organizer role"
  end

  describe "GET /organizer/settings" do
    let(:path) { organizer_settings_path }
    include_examples "requires organizer role"
  end
end
