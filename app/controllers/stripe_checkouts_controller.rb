class StripeCheckoutsController < ApplicationController
  # GET /stripe/checkout/return?slug=:slug
  # Stripe redirects here after a successful payment.
  # The RSVP may not yet be confirmed (webhook is async) — that's expected.
  # The webhook will confirm within seconds; the member will see their name
  # on the attendee list on the next page refresh.
  def return
    @event = current_club.events.published.friendly.find(params[:slug])
    redirect_to event_path(@event),
      notice: "Payment received — check your email for your confirmation and receipt."
  rescue ActiveRecord::RecordNotFound
    # Slug missing, unpublished, or belongs to a different club
    redirect_to events_path,
      notice: "Payment received — check your email for confirmation."
  end
end
