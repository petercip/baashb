class MagicLinksController < ApplicationController
  # Magic links are used for organizer invites (Path 1 onboarding).
  # Primary sign-in is now email/password (SessionsController).
  skip_before_action :require_authentication

  # GET /auth/magic/:token
  # Organizer-invited member clicks their invite email link.
  def verify
    magic_link = MagicLink.find_by(token: params[:token])

    if magic_link.nil?
      return redirect_to new_session_path,
             alert: "This link was already used — or you're already signed in."
    end

    if magic_link.used?
      return redirect_to new_session_path,
             alert: "This link was already used — or you're already signed in."
    end

    if magic_link.expired?
      magic_link.destroy
      return redirect_to new_session_path,
             alert: "This link has expired. Request a new one from your organizer."
    end

    member = magic_link.member
    ActiveRecord::Base.transaction do
      magic_link.consume!
      start_new_session_for(member, request)
    end

    redirect_to after_sign_in_path, notice: "Welcome, #{member.name.split.first}!"
  end
end
