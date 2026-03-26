class ApplicationMailer < ActionMailer::Base
  # "From" address is set per-club from club.smtp_from (or a sensible fallback).
  # Called as: ApplicationMailer.with(club: current_club).some_method
  default from: -> { _club&.smtp_from.presence || "noreply@#{_club&.custom_domain || 'example.com'}" }

  layout "mailer"

  private

  def _club
    params[:club] if respond_to?(:params, true) && params.respond_to?(:[], true)
  end
end
