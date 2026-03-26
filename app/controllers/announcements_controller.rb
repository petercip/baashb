class AnnouncementsController < ApplicationController
  # Members-only announcement archive — requires sign-in.

  def index
    @announcements = current_club.announcements.sent
  end

  def show
    @announcement = current_club.announcements.sent.friendly.find(params[:slug])
  end
end
