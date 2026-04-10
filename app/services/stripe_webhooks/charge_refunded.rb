module StripeWebhooks
  class ChargeRefunded
    # Handles charge.refunded webhook event.
    # Updates refund status on the RSVP after Stripe processes the refund.
    def self.call(charge)
      new(charge).call
    end

    def initialize(charge)
      @charge = charge
    end

    def call
      rsvp = Rsvp.find_by(stripe_charge_id: @charge["id"])

      # Nil guard: handles manual Stripe Dashboard refunds on pre-feature charges
      # where no RSVP exists with this charge_id. Return 200 so Stripe doesn't retry.
      return unless rsvp

      # Idempotency guard: webhook may be delivered more than once
      return if rsvp.refund_succeeded?

      refund_id = @charge.dig("refunds", "data", 0, "id")

      rsvp.update!(
        refund_status:   :refund_succeeded,
        refunded_at:     Time.current,
        stripe_refund_id: refund_id
      )
    end
  end
end
