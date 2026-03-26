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
  end
end
