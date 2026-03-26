class OmniauthCallbacksController < ApplicationController
  skip_before_action :resume_session
  skip_before_action :require_authentication
  # OmniAuth POSTs the callback — skip Rails CSRF for these endpoints only.
  skip_before_action :verify_authenticity_token

  # GET/POST /auth/google_oauth2/callback
  def google
    auth   = request.env["omniauth.auth"]
    email  = auth.info.email.to_s.strip.downcase
    uid    = auth.uid.to_s

    # 1. Look up by Google UID first (already linked)
    member = current_club.members.active.find_by(google_uid: uid)

    # 2. Fall back to email match → link the UID going forward
    if member.nil?
      member = current_club.members.active.find_by(email: email)
      member&.update_columns(google_uid: uid)
    end

    if member
      start_new_session_for(member, request)
      redirect_to after_sign_in_path, notice: "Welcome back, #{member.name.split.first}!"
    else
      redirect_to new_session_path,
                  alert: "No account found for #{email}. Contact an organizer to join #{current_club.name}."
    end
  end

  # /auth/failure
  def failure
    redirect_to new_session_path,
                alert: "Google sign-in failed. Please try email and password instead."
  end
end
