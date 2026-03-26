class Organizer::BaseController < ApplicationController
  before_action :require_organizer!

  private

  def require_organizer!
    unless current_member&.organizer?
      redirect_to root_path, alert: "You don't have permission to access that."
    end
  end
end
