class StripeWebhooksController < ApplicationController
  # Stripe sends raw JSON — skip CSRF and session auth.
  # Signature verification (below) is the authentication mechanism.
  skip_before_action :verify_authenticity_token
  skip_before_action :require_authentication

  # POST /stripe/webhooks
  def create
    payload = request.body.read
    sig     = request.env["HTTP_STRIPE_SIGNATURE"]

    # ClubMiddleware has already resolved Current.club from the Host header.
    # Stripe sends to https://[club-domain]/stripe/webhooks — the club domain IS
    # the host, so the correct club's stripe_webhook_secret is used automatically.
    Stripe.api_key = Current.club.stripe_secret_key
    event = Stripe::Webhook.construct_event(
              payload, sig, Current.club.stripe_webhook_secret)

    case event["type"]
    when "checkout.session.completed"
      StripeWebhooks::CheckoutCompleted.call(event["data"]["object"])
    when "checkout.session.expired"
      StripeWebhooks::CheckoutExpired.call(event["data"]["object"])
    when "charge.refunded"
      StripeWebhooks::ChargeRefunded.call(event["data"]["object"])
    end
    # Unknown event types are silently ignored (safe — forward-compatible)

    head :ok
  rescue Stripe::SignatureVerificationError
    head :bad_request
  end
end
