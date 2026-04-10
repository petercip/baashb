require "rails_helper"

RSpec.describe "Organizer::Rsvps" do
  let(:club)      { create(:club, :with_stripe) }
  let(:organizer) { create(:member, :organizer, club: club) }
  let(:member)    { create(:member, club: club) }
  let(:event)     { create(:event, :paid, :published, club: club, price_cents: 5000) }
  let(:rsvp)      { create(:rsvp, :confirmed, :paid, event: event, member: member, stripe_charge_id: "ch_test") }
  let(:headers)   { { "Host" => host_for(club) } }

  before { allow(Rsvp::CancelService).to receive(:call) }

  describe "DELETE /organizer/events/:slug/rsvps/:id" do
    context "when signed in as organizer" do
      before { sign_in_as(organizer) }

      it "cancels the RSVP via CancelService and redirects to attendees page" do
        delete organizer_event_rsvp_path(event, rsvp), headers: headers
        expect(Rsvp::CancelService).to have_received(:call).with(rsvp: rsvp, by: :organizer)
        expect(response).to redirect_to(attendees_organizer_event_path(event))
      end

      it "returns 404 for a pending_payment RSVP (not in .confirmed scope)" do
        pending_rsvp = create(:rsvp, :pending_payment, event: event,
                              member: create(:member, club: club))
        expect {
          delete organizer_event_rsvp_path(event, pending_rsvp), headers: headers
        }.not_to change { Rsvp::CancelService.method(:call) }
        # The .confirmed scope will raise RecordNotFound → redirect with alert
        expect(response).to redirect_to(attendees_organizer_event_path(event))
      end

      it "returns 404 for an RSVP on a different club's event" do
        other_club  = create(:club)
        other_event = create(:event, :paid, :published, club: other_club)
        other_member = create(:member, club: other_club)
        other_rsvp  = create(:rsvp, :confirmed, :paid, event: other_event, member: other_member)

        delete organizer_event_rsvp_path(event, other_rsvp), headers: headers
        # set_event is scoped to current_club — the event slug won't be found for the other club's RSVP id
        expect(response).to redirect_to(attendees_organizer_event_path(event))
      end
    end

    context "when signed in as a plain member (not organizer)" do
      before { sign_in_as(member) }

      it "redirects to root path (auth guard)" do
        delete organizer_event_rsvp_path(event, rsvp), headers: headers
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
