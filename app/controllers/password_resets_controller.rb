class PasswordResetsController < ApplicationController
  skip_before_action :require_authentication

  # GET /password-reset
  # Form: enter your email to receive a reset link.
  def new; end

  # POST /password-reset
  # Always redirects with a neutral message — never reveals whether an email is registered.
  def create
    email  = params[:email].to_s.strip.downcase
    member = current_club.members.active.find_by(email: email)

    if member
      member.generate_password_reset_token!
      PasswordResetMailer.reset(member).deliver_later
    end

    redirect_to new_session_path,
                notice: "If that email is registered, you'll receive a reset link shortly."
  end

  # GET /password-reset/:token
  # Form: enter a new password.
  def edit
    @member = find_member_by_token!
    return if @member.nil?

    if @member.password_reset_expired?
      redirect_to new_password_reset_path,
                  alert: "That reset link has expired. Request a new one."
    end
  end

  # PATCH /password-reset/:token
  def update
    @member = find_member_by_token!
    return if @member.nil?

    if @member.password_reset_expired?
      return redirect_to new_password_reset_path,
                         alert: "That reset link has expired. Request a new one."
    end

    if @member.update(password_params)
      @member.clear_password_reset_token!
      start_new_session_for(@member, request)
      redirect_to root_path, notice: "Password updated — you're now signed in."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def find_member_by_token!
    member = current_club.members.find_by(password_reset_token: params[:token])
    if member.nil?
      redirect_to new_password_reset_path,
                  alert: "That reset link is invalid or has already been used."
      return nil
    end
    member
  end

  def password_params
    params.require(:member).permit(:password, :password_confirmation)
  end
end
