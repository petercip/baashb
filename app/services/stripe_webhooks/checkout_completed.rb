module StripeWebhooks
  class CheckoutCompleted
    # Handles checkout.session.completed webhook event.
    # Called by StripeWebhooksController with the session object from the webhook payload.
    def self.call(session)
      new(session).call
    end

    def initialize(session)
      @session = session
    end

    def call
      rsvp = find_rsvp
      return unless rsvp

      # Idempotency guard — handle duplicate webhook delivery
      return if rsvp.confirmed?

      rsvp.update!(
        status:           :confirmed,
        paid_at:          Time.current,
        amount_paid_cents: @session["amount_total"],
        stripe_charge_id:  @session.dig("payment_intent", "latest_charge", "id")
      )

      RsvpConfirmationMailer.paid_event_confirmation(rsvp).deliver_later
    end

    private

    def find_rsvp
      # Primary lookup: checkout_session_id (fastest, most reliable)
      rsvp = Rsvp.find_by(checkout_session_id: @session["id"])

      # Fallback: metadata[:rsvp_id] — handles the edge case where checkout_session_id
      # lookup returns nil due to a timing window between session creation and storage
      rsvp ||= Rsvp.find_by(id: @session.dig("metadata", "rsvp_id"))

      rsvp
    end
  end
end
