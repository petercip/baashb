class MembersController < ApplicationController
  # Public profile pages — visible to signed-out visitors too.
  skip_before_action :require_authentication, only: %i[show]

  def show
    @member = current_club.members.active.friendly.find(params[:slug])
  end
end
