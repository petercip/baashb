class SessionsController < ApplicationController
  skip_before_action :require_authentication, only: %i[new create]

  # GET /sign-in
  def new
    redirect_to root_path if current_member
  end

  # POST /sign-in
  def create
    email  = params[:email].to_s.strip.downcase
    member = current_club.members.active.find_by(email: email)

    if member&.authenticate(params[:password])
      start_new_session_for(member, request)
      redirect_to after_sign_in_path, notice: "Welcome back, #{member.name.split.first}!"
    else
      flash.now[:alert] = "Invalid email or password."
      render :new, status: :unprocessable_entity
    end
  end

  # DELETE /sign-out
  def destroy
    terminate_session
    redirect_to new_session_path, notice: "You've been signed out."
  end
end
