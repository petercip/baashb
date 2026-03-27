class RsvpConfirmationMailer < ApplicationMailer
  # RsvpConfirmationMailer.free_event_confirmation(rsvp).deliver_later
  def free_event_confirmation(rsvp)
    @rsvp      = rsvp
    @member    = rsvp.member
    @event     = rsvp.event
    @club      = @event.club
    @event_url = event_url(@event.slug, host: _host_for(@club))

    # Build iCal attachment
    attachments["#{@event.slug}.ics"] = {
      mime_type: "text/calendar",
      content:   build_ical(@event)
    }

    mail(
      to:      @member.email,
      subject: "You're going to #{@event.name}!",
      from:    @club.smtp_from.presence || "noreply@#{_host_for(@club)}"
    )
  end

  private

  def _host_for(club)
    club.custom_domain.presence || "#{club.slug}.#{ActionMailer::Base.default_url_options[:host]}"
  end

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
