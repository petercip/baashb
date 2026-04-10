require "rails_helper"

RSpec.describe "StripeWebhooks" do
  let(:club)    { create(:club, :with_stripe) }
  let(:headers) do
    {
      "Host"              => host_for(club),
      "Content-Type"      => "application/json",
      "HTTP_STRIPE_SIGNATURE" => "valid_sig"
    }
  end

  def stripe_event_payload(type, object = {})
    { type: type, data: { object: object } }.to_json
  end

  def stub_valid_webhook(event_type, object = {})
    fake_event = { "type" => event_type, "data" => { "object" => object } }
    allow(Stripe::Webhook).to receive(:construct_event).and_return(fake_event)
  end

  def stub_invalid_signature
    allow(Stripe::Webhook).to receive(:construct_event)
      .and_raise(Stripe::SignatureVerificationError.new("bad sig", "header"))
  end

  describe "POST /stripe/webhooks" do
    it "returns 400 for an invalid Stripe signature" do
      stub_invalid_signature
      post stripe_webhooks_path, headers: headers, params: "{}"
      expect(response).to have_http_status(:bad_request)
    end

    it "returns 200 and routes checkout.session.completed to CheckoutCompleted" do
      stub_valid_webhook("checkout.session.completed", { "id" => "cs_test" })
      allow(StripeWebhooks::CheckoutCompleted).to receive(:call)
      post stripe_webhooks_path, headers: headers, params: "{}"
      expect(response).to have_http_status(:ok)
      expect(StripeWebhooks::CheckoutCompleted).to have_received(:call)
    end

    it "returns 200 and routes checkout.session.expired to CheckoutExpired" do
      stub_valid_webhook("checkout.session.expired", { "id" => "cs_test" })
      allow(StripeWebhooks::CheckoutExpired).to receive(:call)
      post stripe_webhooks_path, headers: headers, params: "{}"
      expect(response).to have_http_status(:ok)
      expect(StripeWebhooks::CheckoutExpired).to have_received(:call)
    end

    it "returns 200 and routes charge.refunded to ChargeRefunded" do
      stub_valid_webhook("charge.refunded", { "id" => "ch_test" })
      allow(StripeWebhooks::ChargeRefunded).to receive(:call)
      post stripe_webhooks_path, headers: headers, params: "{}"
      expect(response).to have_http_status(:ok)
      expect(StripeWebhooks::ChargeRefunded).to have_received(:call)
    end

    it "returns 200 for an unknown event type (safe no-op)" do
      stub_valid_webhook("payment_intent.created")
      post stripe_webhooks_path, headers: headers, params: "{}"
      expect(response).to have_http_status(:ok)
    end
  end
end
