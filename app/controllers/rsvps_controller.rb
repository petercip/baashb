class RsvpsController < ApplicationController
  before_action :set_event

  # POST /events/:slug/rsvps
  def create
    # Redirect to Stripe for paid events (implemented in next phase)
    unless @event.free?
      return redirect_to event_path(@event),
             alert: "Paid RSVPs are not yet enabled. Please check back soon."
    end

    # Check for duplicate RSVP
    existing = @event.rsvps.find_by(member: current_member)
    if existing&.confirmed?
      return redirect_to event_path(@event), notice: "You're already attending this event."
    end

    rsvp = nil
    ActiveRecord::Base.transaction do
      # Re-read capacity inside the transaction to guard against the race
      # where two members claim the last spot simultaneously.
      event = @event.lock!
      if event.full?
        raise ActiveRecord::Rollback
      end

      rsvp = event.rsvps.create!(
        member: current_member,
        status: :confirmed
        # paid_at intentionally nil for free events (no payment took place)
      )
    end

    if rsvp&.persisted?
      RsvpConfirmationMailer.free_event_confirmation(rsvp).deliver_later
      redirect_to event_path(@event), notice: "You're going to #{@event.name}! Check your email for details."
    else
      redirect_to event_path(@event), alert: "Sorry — this event is sold out."
    end
  end

  # DELETE /rsvps/:id
  def destroy
    @rsvp = current_member.rsvps.find(params[:id])
    @event = @rsvp.event

    # Free event cancellation — no refund logic needed
    if @event.free?
      @rsvp.update!(status: :cancelled, cancelled_at: Time.current)
      return redirect_to event_path(@event), notice: "You've been removed from #{@event.name}."
    end

    # Paid event: check cancel button is visible (paid_at present) and
    # refund cutoff hasn't passed.
    unless @rsvp.cancellable_by_member?
      if @event.refund_cutoff_passed?
        safe_email = ERB::Util.html_escape(current_club.contact_email)
        return redirect_to event_path(@event),
               alert: "The refund cutoff has passed. Contact <a href='mailto:#{safe_email}'>organizers</a>.".html_safe
      end
      return redirect_to event_path(@event), alert: "This RSVP can't be cancelled right now."
    end

    # Stripe refund — implemented in next phase (paid events)
    redirect_to event_path(@event), alert: "Paid event cancellations are not yet enabled."
  end

  private

  def set_event
    # Route is /events/:slug/rsvps — the param name matches the events resource param: :slug
    @event = current_club.events.friendly.find(params[:slug])
  end
end
