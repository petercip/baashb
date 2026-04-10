class Organizer::RsvpsController < Organizer::BaseController
  # DELETE /organizer/events/:event_slug/rsvps/:id
  def destroy
    @event = current_club.events.friendly.find(params[:event_slug])
    @rsvp  = @event.rsvps.confirmed.find(params[:id])

    Rsvp::CancelService.call(rsvp: @rsvp, by: :organizer)
    redirect_to attendees_organizer_event_path(@event),
      notice: "#{@rsvp.member.name}'s RSVP has been cancelled and refunded."
  rescue ActiveRecord::RecordNotFound
    redirect_to attendees_organizer_event_path(@event),
      alert: "RSVP not found."
  rescue => e
    redirect_to attendees_organizer_event_path(@event),
      alert: "Could not cancel RSVP: #{e.message}"
  end
end
