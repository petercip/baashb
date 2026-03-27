class Club < ApplicationRecord
  # Associations
  has_many :members,       dependent: :destroy
  has_many :events,        dependent: :destroy
  has_many :announcements, dependent: :destroy
  has_one_attached :logo
  has_one_attached :cover_image

  # Active Record Encryption for Stripe keys (Rails 7.1+)
  # Keys generated via: rails db:encryption:init
  encrypts :stripe_secret_key, :stripe_publishable_key, :stripe_webhook_secret
  encrypts :smtp_pass

  # Validations
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true,
                   format: { with: /\A[a-z0-9-]+\z/, message: "only lowercase letters, numbers, and hyphens" }
  validates :primary_color, format: { with: /\A#[0-9a-fA-F]{6}\z/ }, allow_blank: true

  # Allowlist of fonts safe to inject into the <style> tag in the layout.
  # Prevents CSS injection via an arbitrary font_choice value.
  # NOTE: Use an array literal (not %w[]) so multi-word names like "Playfair Display" are preserved.
  ALLOWED_FONTS = ["Inter", "Georgia", "Merriweather", "Playfair Display", "Lato", "Raleway", "Roboto"].freeze
  validates :font_choice, inclusion: { in: ALLOWED_FONTS }, allow_blank: true

  # SSL status state machine
  # ┌─────────┐   DNS pointed + ACME  ┌────────┐
  # │ pending │ ─────────────────────►│ active │
  # │         │◄──── retry button ────│ failed │
  # └─────────┘                       └────────┘
  enum :ssl_status, { pending: "pending", active: "active", failed: "failed" }, default: "pending"

  # 501c3 receipt gate: all three legal fields required before receipts can be sent
  def receipt_configured?
    legal_name.present? && ein.present? && ca_registry_number.present?
  end

  # Display name for CSS injection (falls back to safe defaults)
  def css_primary_color
    primary_color.presence || "#c8a96e"
  end

  def css_font_choice
    font_choice.presence || "Inter"
  end
end
