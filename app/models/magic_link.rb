class MagicLink < ApplicationRecord
  belongs_to :member

  before_create :generate_token

  ORGANIZER_INVITE_TTL = 7.days
  SELF_SIGNUP_TTL      = 24.hours

  scope :active, -> { where(used_at: nil).where("expires_at > ?", Time.current) }

  def expired?
    expires_at < Time.current
  end

  def used?
    used_at.present?
  end

  # Mark link as consumed — call inside a transaction with session creation
  def consume!
    update!(used_at: Time.current)
  end

  private

  def generate_token
    self.token      = SecureRandom.urlsafe_base64(32)
    self.expires_at ||= ORGANIZER_INVITE_TTL.from_now
  end
end
