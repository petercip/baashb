require "rails_helper"

RSpec.describe RsvpConfirmationMailer do
  let(:club)   { create(:club, name: "Bay Rowing Club", primary_color: "#c8a96e") }
  let(:member) { create(:member, club: club, name: "Alice Chen", email: "alice@example.com") }
  let(:event)  {
    create(:event, club: club,
           name:        "Spring Rowing Dinner",
           venue:       "The Boathouse, San Francisco",
           starts_at:   Time.zone.parse("2026-04-12 19:00:00"),
           ends_at:     Time.zone.parse("2026-04-12 22:00:00"),
           description: "Join us for dinner and rowing stories.")
  }
  let(:rsvp) { create(:rsvp, :confirmed, event: event, member: member) }

  describe "#free_event_confirmation" do
    subject(:mail) { described_class.free_event_confirmation(rsvp) }

    it "is sent to the member's email" do
      expect(mail.to).to eq([ "alice@example.com" ])
    end

    it "has the event name in the subject" do
      expect(mail.subject).to include("Spring Rowing Dinner")
    end

    it "greets the member by first name in the text part" do
      expect(mail.text_part.body.to_s).to include("Hi Alice,")
    end

    it "includes the event name in the text part" do
      expect(mail.text_part.body.to_s).to include("Spring Rowing Dinner")
    end

    it "includes the venue in the text part" do
      expect(mail.text_part.body.to_s).to include("The Boathouse, San Francisco")
    end

    it "includes the event name in the HTML part" do
      expect(mail.html_part.body.to_s).to include("Spring Rowing Dinner")
    end

    it "attaches a .ics calendar file" do
      attachment = mail.attachments.find { |a| a.filename.end_with?(".ics") }
      expect(attachment).to be_present
      expect(attachment.mime_type).to eq("text/calendar")
    end

    it "includes the event details in the iCal attachment" do
      ics_content = mail.attachments.find { |a| a.filename.end_with?(".ics") }.body.decoded
      expect(ics_content).to include("SUMMARY:Spring Rowing Dinner")
      expect(ics_content).to include("LOCATION:The Boathouse\\, San Francisco")
    end

    it "includes a 24-hour reminder alarm in the iCal" do
      ics_content = mail.attachments.find { |a| a.filename.end_with?(".ics") }.body.decoded
      expect(ics_content).to include("TRIGGER:-PT24H")
    end
  end

  describe "#paid_event_confirmation" do
    let(:paid_event) do
      create(:event, :paid, club: club,
             name:      "Spring Rowing Dinner",
             venue:     "The Boathouse, San Francisco",
             starts_at: Time.zone.parse("2026-04-12 19:00:00"),
             price_cents: 5000)
    end
    let(:paid_rsvp) do
      create(:rsvp, :confirmed, :paid, event: paid_event, member: member,
             donation_amount_cents: 0, amount_paid_cents: 5000)
    end

    subject(:mail) { described_class.paid_event_confirmation(paid_rsvp) }

    it "is sent to the member's email address" do
      expect(mail.to).to eq([ "alice@example.com" ])
    end

    it "has the event name and ticket price in the body" do
      body = mail.html_part.body.to_s
      expect(body).to include("Spring Rowing Dinner")
      expect(body).to include("$50.00")
    end

    it "shows donation amount when donation_amount_cents > 0" do
      paid_rsvp.update!(donation_amount_cents: 2500)
      body = described_class.paid_event_confirmation(paid_rsvp).html_part.body.to_s
      expect(body).to include("$25.00")
    end

    context "receipt block when receipt_configured? is true and donation > 0" do
      before do
        club.update!(
          legal_name:         "Bay Area Rowing Association",
          ein:                "12-3456789",
          ca_registry_number: "CT0001234"
        )
        paid_rsvp.update!(donation_amount_cents: 2500)
      end

      it "shows the receipt block" do
        body = described_class.paid_event_confirmation(paid_rsvp).html_part.body.to_s
        expect(body).to include("CHARITABLE CONTRIBUTION RECEIPT")
        expect(body).to include("12-3456789")
      end
    end

    context "receipt block absent when receipt_configured? is false (EIN not set)" do
      before { paid_rsvp.update!(donation_amount_cents: 2500) }

      it "silently omits the receipt block" do
        body = mail.html_part.body.to_s
        expect(body).not_to include("CHARITABLE CONTRIBUTION RECEIPT")
      end
    end

    context "receipt block when receipt_configured? without ca_registry_number" do
      before do
        club.update!(legal_name: "Bay Area Rowing Association", ein: "12-3456789",
                     ca_registry_number: nil)
        paid_rsvp.update!(donation_amount_cents: 2500)
      end

      it "shows the receipt block without the CA Registry line" do
        body = described_class.paid_event_confirmation(paid_rsvp).html_part.body.to_s
        expect(body).to include("CHARITABLE CONTRIBUTION RECEIPT")
        expect(body).to include("12-3456789")
        expect(body).not_to include("CA Registry")
      end
    end

    context "receipt block absent when donation_amount_cents is 0" do
      before do
        club.update!(legal_name: "Bay Area Rowing Association", ein: "12-3456789",
                     ca_registry_number: "CT0001234")
      end

      it "omits receipt block even if club is receipt_configured?" do
        body = mail.html_part.body.to_s
        expect(body).not_to include("CHARITABLE CONTRIBUTION RECEIPT")
      end
    end

    it "from: is club.smtp_from" do
      club.update!(smtp_from: "noreply@bayrowinclub.org")
      expect(mail.from).to include("noreply@bayrowinclub.org")
    end

    it "reply_to: is club.contact_email" do
      club.update!(contact_email: "contact@bayrowingclub.org")
      expect(mail.reply_to).to include("contact@bayrowingclub.org")
    end
  end
end
