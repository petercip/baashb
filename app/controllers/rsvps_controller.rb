class RsvpsController < ApplicationController
  before_action :set_event

  # POST /events/:slug/rsvps
  def create
    # Redirect to Stripe for paid events (implemented in next phase)
    unless @event.free?
      return redirect_to event_path(@event),
             alert: "Paid RSVPs are not yet enabled. Please check back soon."
    end

    # Check for existing RSVP — guard all statuses to avoid hitting the DB unique index
    existing = @event.rsvps.find_by(member: current_member)
    if existing&.confirmed?
      return redirect_to event_path(@event), notice: "You're already attending this event."
    elsif existing&.pending_payment?
      return redirect_to event_path(@event), alert: "You already have a pending checkout for this event."
    end
    # existing&.cancelled? falls through — allow re-RSVP by reactivating the record below

    rsvp = nil
    ActiveRecord::Base.transaction do
      # Re-read capacity inside the transaction to guard against the race
      # where two members claim the last spot simultaneously.
      event = @event.lock!
      if event.full?
        raise ActiveRecord::Rollback
      end

      if existing # reactivate a previously cancelled RSVP
        existing.update!(status: :confirmed, cancelled_at: nil)
        rsvp = existing
      else
        rsvp = event.rsvps.create!(
          member: current_member,
          status: :confirmed
          # paid_at intentionally nil for free events (no payment took place)
        )
      end
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
        return redirect_to event_path(@event),
               alert: "The refund cutoff has passed. Contact your organizers at #{current_club.contact_email}."
      end
      return redirect_to event_path(@event), alert: "This RSVP can't be cancelled right now."
    end

    # Stripe refund — implemented in next phase (paid events)
    redirect_to event_path(@event), alert: "Paid event cancellations are not yet enabled."
  end

  private

  def set_event
    # Route is /events/:slug/rsvps — scope to published so members can't RSVP to drafts.
    @event = current_club.events.published.friendly.find(params[:slug])
  end
end
