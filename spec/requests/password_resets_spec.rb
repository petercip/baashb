require "rails_helper"

RSpec.describe "PasswordResets" do
  let(:club)    { create(:club) }
  let(:member)  { create(:member, :active, club: club, password: "oldpassword") }
  let(:headers) { { "Host" => host_for(club) } }

  describe "GET /password-reset" do
    it "returns 200 without sign-in" do
      get new_password_reset_path, headers: headers
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /password-reset" do
    it "redirects with neutral message regardless of whether email exists" do
      post password_resets_path,
           params: { email: member.email },
           headers: headers
      expect(response).to redirect_to(new_session_path)
      expect(flash[:notice]).to include("If that email is registered")
    end

    it "sends reset email when member is found" do
      expect {
        post password_resets_path,
             params: { email: member.email },
             headers: headers
      }.to have_enqueued_mail(PasswordResetMailer, :reset)
    end

    it "does not reveal whether an unknown email is registered" do
      post password_resets_path,
           params: { email: "nobody@example.com" },
           headers: headers
      expect(response).to redirect_to(new_session_path)
      expect(flash[:notice]).to include("If that email is registered")
    end

    it "does not send email for an unknown address" do
      expect {
        post password_resets_path,
             params: { email: "nobody@example.com" },
             headers: headers
      }.not_to have_enqueued_mail
    end
  end

  describe "GET /password-reset/:token" do
    context "with a valid, unexpired token" do
      it "returns 200" do
        token = member.generate_token_for(:password_reset)
        get edit_password_reset_path(token), headers: headers
        expect(response).to have_http_status(:ok)
      end
    end

    context "with an expired token" do
      it "redirects with an expiry alert" do
        token = member.generate_token_for(:password_reset)
        travel_to 3.hours.from_now do
          get edit_password_reset_path(token), headers: headers
          expect(response).to redirect_to(new_password_reset_path)
          expect(flash[:alert]).to include("expired")
        end
      end
    end

    context "with a nonexistent token" do
      it "redirects with an invalid alert" do
        get edit_password_reset_path("notarealtoken"), headers: headers
        expect(response).to redirect_to(new_password_reset_path)
        expect(flash[:alert]).to include("invalid")
      end
    end
  end

  describe "PATCH /password-reset/:token" do
    let(:token) { member.generate_token_for(:password_reset) }

    context "with valid token and matching passwords" do
      it "updates the password, signs in, and redirects to root" do
        patch password_reset_path(token),
              params: { member: { password: "newpassword1", password_confirmation: "newpassword1" } },
              headers: headers
        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to include("Password updated")
      end

      it "auto-invalidates old token after password change" do
        patch password_reset_path(token),
              params: { member: { password: "newpassword1", password_confirmation: "newpassword1" } },
              headers: headers
        # Token uses password_salt as rotating component — old token now invalid
        get edit_password_reset_path(token), headers: headers
        expect(response).to redirect_to(new_password_reset_path)
      end
    end

    context "with an expired token" do
      it "redirects with an expiry alert without updating the password" do
        expired_token = token # force lazy let evaluation before time travel
        travel_to 3.hours.from_now do
          patch password_reset_path(expired_token),
                params: { member: { password: "newpassword1", password_confirmation: "newpassword1" } },
                headers: headers
          expect(response).to redirect_to(new_password_reset_path)
          expect(flash[:alert]).to include("expired")
        end
        expect(member.reload.authenticate("newpassword1")).to be_falsey
      end
    end
  end
end
