class Session < ApplicationRecord
  belongs_to :member

  before_create :generate_token

  SESSION_TTL = 30.days

  def expired?
    expires_at < Time.current
  end

  private

  def generate_token
    self.token      = SecureRandom.urlsafe_base64(32)
    self.expires_at ||= SESSION_TTL.from_now
  end
end
