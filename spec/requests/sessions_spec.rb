require "rails_helper"

RSpec.describe "Sessions" do
  let(:club)    { create(:club) }
  let(:member)  { create(:member, club: club, password: "s3cr3tpassword") }
  let(:headers) { { "Host" => host_for(club) } }

  describe "GET /sign-in" do
    it "returns 200 for a signed-out visitor" do
      get new_session_path, headers: headers
      expect(response).to have_http_status(:ok)
    end

    it "redirects to root when already signed in" do
      sign_in_as(member, password: "s3cr3tpassword")
      get new_session_path, headers: headers
      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /sign-in (email/password)" do
    context "with correct credentials" do
      it "creates a session and redirects to root" do
        expect {
          post session_path,
               params: { email: member.email, password: "s3cr3tpassword" },
               headers: headers
        }.to change { member.sessions.count }.by(1)

        expect(response).to redirect_to(root_path)
      end

      it "sets a signed session cookie" do
        post session_path,
             params: { email: member.email, password: "s3cr3tpassword" },
             headers: headers
        expect(cookies[:session_token]).to be_present
      end
    end

    context "with wrong password" do
      it "re-renders the sign-in form with 422" do
        post session_path,
             params: { email: member.email, password: "wrongpassword" },
             headers: headers
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Invalid email or password")
      end

      it "does not create a session record" do
        expect {
          post session_path,
               params: { email: member.email, password: "wrongpassword" },
               headers: headers
        }.not_to change { Session.count }
      end
    end

    context "with an unknown email" do
      it "re-renders the sign-in form (no user enumeration)" do
        post session_path,
             params: { email: "nobody@example.com", password: "anything" },
             headers: headers
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Invalid email or password")
      end
    end

    context "with an inactive (removed) member" do
      let!(:removed_member) { create(:member, :removed, club: club, password: "s3cr3tpassword") }

      it "refuses sign-in" do
        post session_path,
             params: { email: removed_member.email, password: "s3cr3tpassword" },
             headers: headers
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "session resume (resume_session)" do
    context "when member is removed after an active session is established" do
      it "treats the next request as unauthenticated and redirects to sign-in" do
        # Sign in to establish a valid session cookie
        sign_in_as(member, password: "s3cr3tpassword")
        # Simulate member being removed by an organizer
        member.update!(status: :removed)
        # Next request with the still-valid cookie must be rejected
        get events_path, headers: headers
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "DELETE /sign-out" do
    it "destroys the session and redirects to sign-in" do
      sign_in_as(member, password: "s3cr3tpassword")
      delete sign_out_path, headers: headers
      expect(response).to redirect_to(new_session_path)
    end
  end
end
