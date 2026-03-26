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
  # Rails 8's has_secure_password auto-registers generates_token_for :password_reset.
  # We override it here to use a 2-hour TTL instead of the default 15 minutes.
  generates_token_for :password_reset, expires_in: 2.hours do
    # Rotates automatically when the member changes their password.
    password_salt&.last(10)
  end
end
