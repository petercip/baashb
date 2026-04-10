require "rails_helper"

RSpec.describe "StripeCheckouts" do
  let(:club)    { create(:club) }
  let(:member)  { create(:member, club: club) }
  let(:event)   { create(:event, :published, club: club) }
  let(:headers) { { "Host" => host_for(club) } }

  describe "GET /stripe/checkout/return" do
    before { sign_in_as(member) }

    it "redirects to the event page with a confirmation notice for a valid slug" do
      get stripe_checkout_return_path, headers: headers,
          params: { slug: event.slug }
      expect(response).to redirect_to(event_path(event))
      expect(flash[:notice]).to include("Payment received")
    end

    it "redirects to events index for an invalid or unpublished slug" do
      get stripe_checkout_return_path, headers: headers,
          params: { slug: "nonexistent-event" }
      expect(response).to redirect_to(events_path)
      expect(flash[:notice]).to include("Payment received")
    end
  end
end
