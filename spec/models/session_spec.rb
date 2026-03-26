require "rails_helper"

RSpec.describe Session do
  subject(:session) { build(:session) }

  describe "associations" do
    it { is_expected.to belong_to(:member) }
  end

  describe "token generation" do
    it "generates a unique token before create" do
      session = create(:session)
      expect(session.token).to be_present
      expect(session.token.length).to be >= 32
    end

    it "generates different tokens for different sessions" do
      a = create(:session)
      b = create(:session, member: a.member)
      expect(a.token).not_to eq(b.token)
    end
  end

  describe "SESSION_TTL constant" do
    it "is 30 days" do
      expect(Session::SESSION_TTL).to eq(30.days)
    end
  end
end
