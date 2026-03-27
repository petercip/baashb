class EventsController < ApplicationController
  # show is publicly accessible — shareable event links work without sign-in.
  # index requires auth (members-only event list).
  # calendar requires a confirmed RSVP (checked inline).
  skip_before_action :require_authentication, only: %i[show]

  def index
    @upcoming_events = current_club.events.published.upcoming
    @past_events     = current_club.events.published.past.limit(10)
    # Preload the current member's RSVPs for all displayed events in one query
    # to avoid N+1 from _event_row calling event.rsvps.find_by per row.
    if current_member
      all_ids = (@upcoming_events.map(&:id) + @past_events.map(&:id))
      @member_rsvps = current_member.rsvps.where(event_id: all_ids).index_by(&:event_id)
    end
  end

  def show
    # Scope to published — draft/cancelled events 404 for non-organizers.
    # Organizers use the organizer namespace (/organizer/events/:slug) to preview drafts.
    @event = current_club.events.published.friendly.find(params[:slug])
    @rsvp  = @event.rsvps.find_by(member: current_member)
  end

  # GET /events/:slug/calendar.ics
  # Serves the iCal file for confirmed attendees.
  def calendar
    @event = current_club.events.published.friendly.find(params[:slug])
    @rsvp  = @event.rsvps.confirmed.find_by(member: current_member)

    unless @rsvp
      return redirect_to event_path(@event),
             alert: "You must be attending this event to download the calendar invite."
    end

    send_data build_ical(@event),
              type:        "text/calendar; charset=utf-8",
              disposition: "attachment",
              filename:    "#{@event.slug}.ics"
  end

  private

  def build_ical(event)
    cal = Icalendar::Calendar.new
    cal.event do |e|
      e.dtstart  = Icalendar::Values::DateTime.new(event.starts_at.utc)
      e.dtend    = Icalendar::Values::DateTime.new((event.ends_at || event.starts_at + 2.hours).utc)
      e.summary  = event.name
      e.location = event.venue
      e.description = event.description.presence || ""
      e.alarm do |a|
        a.action      = "DISPLAY"
        a.trigger     = "-PT24H"
        a.description = "#{event.name} is tomorrow!"
      end
    end
    cal.publish
    cal.to_ical
  end
end
