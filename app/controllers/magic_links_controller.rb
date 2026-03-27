class MagicLinksController < ApplicationController
  # Magic links are used for organizer invites (Path 1 onboarding).
  # Primary sign-in is now email/password (SessionsController).
  skip_before_action :require_authentication

  # GET /auth/magic/:token
  # Organizer-invited member clicks their invite email link.
  def verify
    # All checks + consume happen inside a single transaction with a row lock
    # to prevent two concurrent requests from both passing the used? guard.
    member = nil
    success = false
    expired_link = nil  # captured outside transaction so destroy actually commits

    ActiveRecord::Base.transaction do
      magic_link = MagicLink.lock.find_by(token: params[:token])

      if magic_link.nil? || magic_link.used?
        redirect_to new_session_path,
                    alert: "This link was already used — or you're already signed in."
        raise ActiveRecord::Rollback
      end

      if magic_link.expired?
        expired_link = magic_link  # destroy outside transaction — rollback would undo it
        redirect_to new_session_path,
                    alert: "This link has expired. Request a new one from your organizer."
        raise ActiveRecord::Rollback
      end

      member = magic_link.member

      # Cross-club guard: the link must belong to the current club.
      unless member.club == Current.club
        redirect_to new_session_path,
                    alert: "This invite link is not valid for this club."
        raise ActiveRecord::Rollback
      end

      # Status guard: only active members may sign in via magic link.
      unless member.active?
        redirect_to new_session_path,
                    alert: "Your account is not yet active. Contact your organizer."
        raise ActiveRecord::Rollback
      end

      magic_link.consume!
      start_new_session_for(member, request)
      success = true
    end

    expired_link&.destroy  # cleanup after transaction so the destroy actually commits
    redirect_to after_sign_in_path, notice: "Welcome, #{member.name.split.first}!" if success
  end
end
