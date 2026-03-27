require "rails_helper"

RSpec.describe "MagicLinks (organizer invite)" do
  let(:club)    { create(:club) }
  let(:member)  { create(:member, club: club) }
  let(:headers) { { "Host" => host_for(club) } }

  # The magic link verify endpoint is kept for organizer onboarding (Path 1).
  describe "GET /auth/magic/:token" do
    context "with a valid token" do
      let!(:magic_link) { create(:magic_link, member: member) }

      it "signs the member in and redirects to root" do
        get magic_link_verify_path(magic_link.token), headers: headers
        expect(response).to redirect_to(root_path)
      end

      it "marks the magic link as used" do
        get magic_link_verify_path(magic_link.token), headers: headers
        expect(magic_link.reload.used?).to be true
      end

      it "creates a session" do
        expect {
          get magic_link_verify_path(magic_link.token), headers: headers
        }.to change { member.sessions.count }.by(1)
      end
    end

    context "with an expired token" do
      let!(:magic_link) { create(:magic_link, :expired, member: member) }

      it "redirects to sign-in with a flash alert containing 'expired'" do
        get magic_link_verify_path(magic_link.token), headers: headers
        expect(response).to redirect_to(new_session_path)
        expect(flash[:alert]).to include("expired")
      end
    end

    context "with an already-used token" do
      let!(:magic_link) { create(:magic_link, :used, member: member) }

      it "redirects to sign-in" do
        get magic_link_verify_path(magic_link.token), headers: headers
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "with a nonexistent token" do
      it "redirects to sign-in" do
        get magic_link_verify_path("bogus-token-that-does-not-exist"), headers: headers
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "with a cross-club token (member belongs to a different club)" do
      let(:other_club)   { create(:club, slug: "other-club") }
      let(:other_member) { create(:member, club: other_club) }
      let!(:magic_link)  { create(:magic_link, member: other_member) }

      it "redirects to sign-in with a not-valid-for-this-club alert" do
        # Request arrives in the context of `club` (host header), but the
        # magic link token belongs to a member of `other_club`.
        get magic_link_verify_path(magic_link.token), headers: headers
        expect(response).to redirect_to(new_session_path)
        expect(flash[:alert]).to include("not valid for this club")
      end

      it "does not sign the member in or create a session" do
        expect {
          get magic_link_verify_path(magic_link.token), headers: headers
        }.not_to change { other_member.sessions.count }
      end
    end

    context "with a token for an inactive (removed) member" do
      let!(:removed_member) { create(:member, :removed, club: club) }
      let!(:magic_link)     { create(:magic_link, member: removed_member) }

      it "redirects to sign-in and does not create a session" do
        expect {
          get magic_link_verify_path(magic_link.token), headers: headers
        }.not_to change { removed_member.sessions.count }

        expect(response).to redirect_to(new_session_path)
        expect(flash[:alert]).to include("not yet active")
      end
    end
  end
end
