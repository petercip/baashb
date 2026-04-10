module StripeWebhooks
  class CheckoutExpired
    # Handles checkout.session.expired webhook event.
    # Destroys the pending RSVP directly (NOT via CancelService — no refund since
    # payment never completed). Destroying the RSVP releases the capacity slot.
    def self.call(session)
      new(session).call
    end

    def initialize(session)
      @session = session
    end

    def call
      rsvp = Rsvp.find_by(checkout_session_id: @session["id"])
      return unless rsvp
      return if rsvp.confirmed? # guard: don't destroy a confirmed RSVP

      rsvp.destroy
    end
  end
end
