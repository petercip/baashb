class RsvpsController < ApplicationController
  before_action :set_event

  # GET /events/:slug/rsvp — pre-checkout donation form (paid events only)
  def new
    redirect_to event_path(@event) if @event.free?
  end

  # POST /events/:slug/rsvps
  def create
    # ── Paid event path ──────────────────────────────────────────────────────
    unless @event.free?
      donation_cents = params[:donation_cents].to_i

      result = Rsvp::CheckoutService.call(
        event:          @event,
        member:         current_member,
        donation_cents: donation_cents,
        success_url:    stripe_checkout_return_url(slug: @event.slug),
        cancel_url:     event_url(@event)
      )

      if result[:checkout_url]
        return redirect_to result[:checkout_url], allow_other_host: true
      else
        return redirect_to event_path(@event), alert: result[:error]
      end
    end

    # ── Free event path ───────────────────────────────────────────────────────

    # Guard existing RSVPs for free events
    existing = @event.rsvps.find_by(member: current_member)
    if existing&.confirmed?
      return redirect_to event_path(@event), notice: "You're already attending this event."
    elsif existing&.pending_payment?
      return redirect_to event_path(@event), alert: "You already have a pending checkout for this event."
    end

    rsvp = nil
    ActiveRecord::Base.transaction do
      event = @event.lock!
      if event.full?
        raise ActiveRecord::Rollback
      end

      if existing # reactivate cancelled RSVP
        existing.update!(status: :confirmed, cancelled_at: nil)
        rsvp = existing
      else
        rsvp = event.rsvps.create!(
          member: current_member,
          status: :confirmed
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

    Rsvp::CancelService.call(rsvp: @rsvp, by: :member)
    redirect_to event_path(@event), notice: "You've been removed from #{@event.name}."
  rescue => e
    redirect_to event_path(@event), alert: e.message
  end

  private

  def set_event
    @event = current_club.events.published.friendly.find(params[:slug])
  end
end
