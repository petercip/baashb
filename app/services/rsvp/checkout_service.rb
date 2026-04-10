class Rsvp
  class CheckoutService
    # Rsvp::CheckoutService.call(event:, member:, donation_cents: 0, success_url:, cancel_url:)
    # Returns: { checkout_url: String } or { error: String }
    #
    # URL helpers are not available in PORO service objects — success_url and
    # cancel_url are passed in from RsvpsController#create.
    def self.call(event:, member:, donation_cents: 0, success_url:, cancel_url:)
      new(event: event, member: member, donation_cents: donation_cents,
          success_url: success_url, cancel_url: cancel_url).call
    end

    def initialize(event:, member:, donation_cents:, success_url:, cancel_url:)
      @event          = event
      @member         = member
      @donation_cents = donation_cents.to_i
      @success_url    = success_url
      @cancel_url     = cancel_url
      @club           = event.club
    end

    def call
      rsvp = nil

      ActiveRecord::Base.transaction do
        # Lock the event row to prevent oversell races
        locked_event = @event.lock!

        if locked_event.full?
          return { error: "Sorry — this event is sold out." }
        end

        rsvp = find_or_create_rsvp
      end

      session = create_checkout_session(rsvp)
      return { error: session[:error] } if session[:error]

      rsvp.update!(checkout_session_id: session[:session_id])
      { checkout_url: session[:url] }
    rescue Stripe::StripeError => e
      { error: e.message }
    end

    private

    def find_or_create_rsvp
      existing = @event.rsvps.find_by(member: @member)

      if existing&.confirmed?
        raise "You are already attending this event."
      elsif existing&.pending_payment?
        raise "You already have a pending checkout for this event."
      elsif existing # cancelled — reactivate
        existing.update!(
          status:              :pending_payment,
          cancelled_at:        nil,
          paid_at:             nil,
          amount_paid_cents:   nil,
          stripe_charge_id:    nil,
          refund_status:       nil,
          checkout_session_id: nil,
          donation_amount_cents: @donation_cents
        )
        existing
      else
        @event.rsvps.create!(
          member:               @member,
          status:               :pending_payment,
          donation_amount_cents: @donation_cents
        )
      end
    end

    def create_checkout_session(rsvp)
      line_items = [ticket_line_item]
      line_items << donation_line_item if @donation_cents > 0

      Stripe.api_key = @club.stripe_secret_key

      session = Stripe::Checkout::Session.create(
        mode:        "payment",
        line_items:  line_items,
        success_url: @success_url,
        cancel_url:  @cancel_url,
        expires_at:  30.minutes.from_now.to_i,
        expand:      ["payment_intent.latest_charge"],
        metadata: {
          rsvp_id:   rsvp.id,
          member_id: @member.id,
          club_id:   @club.id
        }
      )

      { session_id: session.id, url: session.url }
    rescue Stripe::StripeError => e
      { error: e.message }
    end

    def ticket_line_item
      {
        price_data: {
          currency:     "usd",
          unit_amount:  @event.price_cents,
          product_data: { name: @event.name }
        },
        quantity: 1
      }
    end

    def donation_line_item
      {
        price_data: {
          currency:     "usd",
          unit_amount:  @donation_cents,
          product_data: { name: "Charitable donation to #{@club.name}" }
        },
        quantity: 1
      }
    end
  end
end

