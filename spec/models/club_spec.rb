require "rails_helper"

RSpec.describe Club do
  subject(:club) { build(:club) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:slug) }
    it { is_expected.to validate_uniqueness_of(:slug) }
  end

  describe "associations" do
    it { is_expected.to have_many(:members) }
    it { is_expected.to have_many(:events) }
    it { is_expected.to have_many(:announcements) }
  end

  describe "#css_primary_color" do
    it "returns the primary_color when set" do
      club.primary_color = "#c8a96e"
      expect(club.css_primary_color).to eq("#c8a96e")
    end

    it "returns a default gold when primary_color is blank" do
      club.primary_color = nil
      expect(club.css_primary_color).to eq("#c8a96e")
    end
  end

  describe "#css_font_choice" do
    it "returns the font_choice when set" do
      club.font_choice = "Inter"
      expect(club.css_font_choice).to eq("Inter")
    end

    it "returns Inter as default when font_choice is blank" do
      club.font_choice = nil
      expect(club.css_font_choice).to eq("Inter")
    end
  end

  describe "#receipt_configured?" do
    it "returns true when all receipt fields are present" do
      club.legal_name = "Bay Area Alumni Sports Hub"
      club.ein = "12-3456789"
      club.ca_registry_number = "CT0123456"
      expect(club.receipt_configured?).to be true
    end

    it "returns false when any receipt field is missing" do
      club.legal_name = "Bay Area Alumni Sports Hub"
      club.ein = nil
      club.ca_registry_number = nil
      expect(club.receipt_configured?).to be false
    end
  end

  describe "ssl_status enum" do
    it "has pending, active, and failed states" do
      expect(Club.ssl_statuses.keys).to contain_exactly("pending", "active", "failed")
    end
  end
end
