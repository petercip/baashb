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
end
