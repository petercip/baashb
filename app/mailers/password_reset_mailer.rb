class PasswordResetMailer < ApplicationMailer
  # Sends a password reset link to the member.
  # Link expires after Member::PASSWORD_RESET_TTL (2 hours).
  def reset(member)
    @member = member
    @club   = member.club
    @url    = edit_password_reset_url(
      @member.password_reset_token,
      host: _host_for(@club)
    )

    mail(
      to:      @member.email,
      subject: "Reset your #{@club.name} password",
      from:    @club.smtp_from.presence || "no-reply@#{_host_for(@club)}"
    )
  end

  private

  def _host_for(club)
    club.custom_domain.presence || "#{club.slug}.#{ActionMailer::Base.default_url_options[:host]}"
  end
end
