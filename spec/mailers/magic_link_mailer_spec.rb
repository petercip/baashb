require "rails_helper"

RSpec.describe MagicLinkMailer do
  let(:club)       { create(:club, name: "Bay Rowing Club") }
  let(:member)     { create(:member, club: club, name: "Alice Chen", email: "alice@example.com") }
  let(:magic_link) { create(:magic_link, member: member) }

  describe "#sign_in" do
    subject(:mail) { described_class.sign_in(magic_link) }

    it "is sent to the member's email" do
      expect(mail.to).to eq(["alice@example.com"])
    end

    it "greets the member by first name in the text part" do
      expect(mail.text_part.body.to_s).to include("Hi Alice,")
    end

    it "includes the magic link token in the body" do
      expect(mail.text_part.body.to_s).to include(magic_link.token)
    end

    it "mentions the expiry in the text body" do
      expect(mail.text_part.body.to_s).to include("expires in")
    end
  end
end
