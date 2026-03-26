require "rails_helper"

RSpec.describe Member do
  subject(:member) { build(:member) }

  describe "associations" do
    it { is_expected.to belong_to(:club) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:email) }

    it "validates uniqueness of email scoped to club" do
      existing = create(:member)
      duplicate = build(:member, club: existing.club, email: existing.email)
      expect(duplicate).not_to be_valid
    end

    it "allows the same email in a different club" do
      club_a = create(:club)
      club_b = create(:club)
      create(:member, club: club_a, email: "shared@example.com")
      member_b = build(:member, club: club_b, email: "shared@example.com")
      expect(member_b).to be_valid
    end
  end

  describe "email normalization" do
    it "downcases and strips whitespace from email" do
      member = create(:member, email: "  Alice@EXAMPLE.COM  ")
      expect(member.reload.email).to eq("alice@example.com")
    end
  end

  describe "slug" do
    it "generates a slug from the name on create" do
      member = create(:member, name: "Alice Chen")
      expect(member.slug).to eq("alice-chen")
    end

    it "regenerates the slug when the name changes" do
      member = create(:member, name: "Alice Chen")
      member.update!(name: "Alice Wong")
      expect(member.reload.slug).to eq("alice-wong")
    end

    it "creates a slug history entry when the slug changes (enabling 301 redirects)" do
      member = create(:member, name: "Alice Chen")
      member.update!(name: "Alice Wong")
      expect(FriendlyId::Slug.where(sluggable: member).count).to be >= 2
    end
  end

  describe "role enum" do
    it { is_expected.to define_enum_for(:role).with_values(member: "member", organizer: "organizer").backed_by_column_of_type(:string) }

    it "is member by default" do
      expect(build(:member).role).to eq("member")
    end
  end

  describe "status enum" do
    it { is_expected.to define_enum_for(:status).with_values(pending: "pending", active: "active", removed: "removed").backed_by_column_of_type(:string) }
  end
end
