class Member < ApplicationRecord
  include ClubScoped
  extend FriendlyId

  # Slug scoped to club — alice-chen can exist in Club A and Club B independently
  friendly_id :name, use: [ :slugged, :scoped, :history ], scope: :club

  # Associations
  has_many :sessions,    dependent: :destroy
  has_many :magic_links, dependent: :destroy
  has_many :rsvps,       dependent: :destroy
  has_many :events, through: :rsvps

  # Password authentication (validations: false → Google-only members have no password)
  has_secure_password validations: false

  # Role
  # ┌────────┐   granted by organizer   ┌───────────┐
  # │ member │ ────────────────────────►│ organizer │
  # └────────┘                          └───────────┘
  enum :role, { member: "member", organizer: "organizer" }, default: "member"

  # Status
  # ┌─────────┐  verify email + org approval  ┌────────┐  org removes  ┌─────────┐
  # │ pending │ ─────────────────────────────►│ active │──────────────►│ removed │
  # └─────────┘                               └────────┘               └─────────┘
  enum :status, { pending: "pending", active: "active", removed: "removed" }, default: "pending"

  # Validations
  validates :email, presence: true, uniqueness: { scope: :club_id },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true

  # Normalize email before save
  normalizes :email, with: ->(email) { email.strip.downcase }

  # Regenerate slug when name changes (history table issues 301s from old slugs).
  # FriendlyId 5.5+ no longer regenerates by default — we opt in explicitly.
  def should_generate_new_friendly_id?
    slug.nil? || name_changed?
  end

  # ── Password Reset ────────────────────────────────────────────────────────────

  PASSWORD_RESET_TTL = 2.hours

  # Populate a fresh reset token and timestamp, persist immediately.
  def generate_password_reset_token!
    update!(
      password_reset_token:   SecureRandom.urlsafe_base64(32),
      password_reset_sent_at: Time.current
    )
  end

  # Returns true when the reset window has closed (nil = never requested).
  def password_reset_expired?
    password_reset_sent_at.nil? ||
      password_reset_sent_at < PASSWORD_RESET_TTL.ago
  end

  # Clear the token after a successful reset.
  def clear_password_reset_token!
    update_columns(
      password_reset_token:   nil,
      password_reset_sent_at: nil
    )
  end
end
