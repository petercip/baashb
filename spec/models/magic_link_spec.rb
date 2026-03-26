require "rails_helper"

RSpec.describe MagicLink do
  subject(:link) { build(:magic_link) }

  describe "associations" do
    it { is_expected.to belong_to(:member) }
  end

  describe "token generation" do
    it "generates a unique token before create" do
      link = create(:magic_link)
      expect(link.token).to be_present
      expect(link.token.length).to be >= 32
    end

    it "generates different tokens for different links" do
      a = create(:magic_link)
      b = create(:magic_link, member: a.member)
      expect(a.token).not_to eq(b.token)
    end
  end

  describe "#expired?" do
    it "returns false when expires_at is in the future" do
      link.expires_at = 1.day.from_now
      expect(link.expired?).to be false
    end

    it "returns true when expires_at is in the past" do
      link.expires_at = 1.second.ago
      expect(link.expired?).to be true
    end
  end

  describe "#used?" do
    it "returns false when used_at is nil" do
      link.used_at = nil
      expect(link.used?).to be false
    end

    it "returns true when used_at is present" do
      link.used_at = 1.hour.ago
      expect(link.used?).to be true
    end
  end

  describe "#consume!" do
    it "sets used_at and saves" do
      link = create(:magic_link)
      expect { link.consume! }.to change { link.reload.used_at }.from(nil)
    end
  end

  describe ".active scope" do
    it "returns links that are unused and not expired" do
      active = create(:magic_link)
      used   = create(:magic_link, :used, member: active.member)
      expired = create(:magic_link, :expired, member: active.member)

      expect(MagicLink.active).to include(active)
      expect(MagicLink.active).not_to include(used, expired)
    end
  end

  describe "TTL constants" do
    it "has a 7-day organizer invite TTL" do
      expect(MagicLink::ORGANIZER_INVITE_TTL).to eq(7.days)
    end

    it "has a 24-hour self-signup TTL" do
      expect(MagicLink::SELF_SIGNUP_TTL).to eq(24.hours)
    end
  end
end
