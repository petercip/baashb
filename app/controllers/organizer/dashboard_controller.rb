class Organizer::DashboardController < Organizer::BaseController
  def index
    @upcoming_events = current_club.events.published.upcoming.limit(5)
    @member_count    = current_club.members.active.count
  end
end
