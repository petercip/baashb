class Rsvp
  class CancelService
    # Rsvp::CancelService.call(rsvp:, by:)
    # :by is :member or :organizer — controls whether refund cutoff is enforced.
    #
    # :member path — enforces paid_at.present? + refund cutoff (via cancellable_by_member?)
    # :organizer path — bypasses refund cutoff; still requires paid_at.present?
    #
    # Free event: cancels directly, no Stripe call.
    # Paid event: issues full Stripe refund via stripe_charge_id, then marks cancelled.
    def self.call(rsvp:, by:)
      new(rsvp: rsvp, by: by).call
    end

    def initialize(rsvp:, by:)
      @rsvp = rsvp
      @event = rsvp.event
      @by   = by
    end

    def call
      if @event.free?
        cancel_free_rsvp
      else
        cancel_paid_rsvp
      end
    end

    private

    def cancel_free_rsvp
      @rsvp.update!(status: :cancelled, cancelled_at: Time.current)
    end

    def cancel_paid_rsvp
      # Guard: stripe_charge_id is only reliable after checkout.session.completed webhook
      raise "Cannot cancel — payment has not been confirmed yet." unless @rsvp.paid_at.present?

      # Member path enforces cutoff; organizer path bypasses it
      if @by == :member && !@rsvp.cancellable_by_member?
        raise "Cancellation is no longer allowed (refund cutoff has passed)."
      end

      issue_stripe_refund

      @rsvp.update!(
        status:        :cancelled,
        cancelled_at:  Time.current,
        refund_status: :refund_pending
      )
    end

    def issue_stripe_refund
      club = @event.club
      Stripe.api_key = club.stripe_secret_key

      Stripe::Refund.create(charge: @rsvp.stripe_charge_id)
    rescue Stripe::StripeError => e
      raise "Stripe refund failed: #{e.message}"
    end
  end
end
