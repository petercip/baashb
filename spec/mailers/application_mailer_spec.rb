require "rails_helper"

RSpec.describe ApplicationMailer do
  # Test the club_mail helper through a concrete subclass
  let(:club) { create(:club, name: "Test Club") }

  # Create a minimal throwaway mailer class to test the helper
  let(:mailer_class) do
    Class.new(ApplicationMailer) do
      def test_mail(club, recipient)
        club_mail(club, to: recipient, subject: "Test", body: "test body")
      end
    end
  end

  describe "#club_mail" do
    it "sets from: to smtp_from when present" do
      club.update!(smtp_from: "noreply@testclub.org")
      mail = mailer_class.new.test_mail(club, "user@example.com")
      expect(mail.from).to include("noreply@testclub.org")
    end

    it "falls back to noreply@{club-domain} when smtp_from is blank" do
      club.update!(smtp_from: nil)
      mail = mailer_class.new.test_mail(club, "user@example.com")
      expect(mail.from.first).to start_with("noreply@")
    end

    it "sets reply_to: from contact_email when present" do
      club.update!(contact_email: "contact@testclub.org")
      mail = mailer_class.new.test_mail(club, "user@example.com")
      expect(mail.reply_to).to include("contact@testclub.org")
    end

    it "omits reply_to header when contact_email is blank" do
      club.update!(contact_email: nil)
      mail = mailer_class.new.test_mail(club, "user@example.com")
      expect(mail.reply_to).to be_blank
    end
  end
end
