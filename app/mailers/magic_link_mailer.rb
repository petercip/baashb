class MagicLinkMailer < ApplicationMailer
  # MagicLinkMailer.sign_in(magic_link).deliver_later
  def sign_in(magic_link)
    @magic_link = magic_link
    @member     = magic_link.member
    @club       = @member.club
    @verify_url = magic_link_verify_url(@magic_link.token, host: _host_for(@club))

    mail(
      to:      @member.email,
      subject: "Sign in to #{@club.name}"
    )
  end

  # MagicLinkMailer.organizer_invite(magic_link).deliver_later
  # Sent when an organizer invites a new member by email.
  def organizer_invite(magic_link)
    @magic_link = magic_link
    @member     = magic_link.member
    @club       = @member.club
    @verify_url = magic_link_verify_url(@magic_link.token, host: _host_for(@club))

    mail(
      to:      @member.email,
      subject: "You've been invited to join #{@club.name}"
    )
  end

  private

  def _host_for(club)
    club.custom_domain.presence || "#{club.slug}.#{ActionMailer::Base.default_url_options[:host]}"
  end
end
