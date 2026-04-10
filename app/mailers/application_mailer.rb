class ApplicationMailer < ActionMailer::Base
  # "From" address is set per-club from club.smtp_from (or a sensible fallback).
  # Called as: ApplicationMailer.with(club: current_club).some_method
  default from: -> { _club&.smtp_from.presence || "noreply@#{_club&.custom_domain || 'example.com'}" }

  layout "mailer"

  # Shared helper for club-scoped mailers.
  # Sets from: (smtp_from or noreply fallback) and reply_to: (contact_email if present).
  # Use instead of bare mail() in any mailer that sends on behalf of a club.
  def club_mail(club, **opts)
    mail(
      from:     club.smtp_from.presence || "noreply@#{_host_for_club(club)}",
      reply_to: club.contact_email.presence,
      **opts
    )
  end

  private

  def _club
    params[:club] if respond_to?(:params, true) && params.respond_to?(:[], true)
  end

  def _host_for_club(club)
    club.custom_domain.presence || "#{club.slug}.#{ActionMailer::Base.default_url_options[:host]}"
  end
end
