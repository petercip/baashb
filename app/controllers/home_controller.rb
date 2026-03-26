class HomeController < ApplicationController
  skip_before_action :require_authentication

  # GET /
  # Signed-in members → events list.
  # Signed-out visitors → club landing page with cover image and sign-in CTA.
  def index
    redirect_to events_path if current_member
  end
end
