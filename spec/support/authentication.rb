# Helpers for signing in a member in request/system specs.
# POSTs email + password to the sessions endpoint, which sets the session cookie
# for all subsequent requests in the same example.
module AuthenticationHelpers
  def sign_in_as(member, password: "password")
    post session_path,
         params:  { email: member.email, password: password },
         headers: { "Host" => host_for(member.club) }
  end

  # Build the lvh.me subdomain host for a club, matching ClubMiddleware logic.
  def host_for(club)
    club.custom_domain.presence || "#{club.slug}.lvh.me"
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelpers, type: :request
  config.include AuthenticationHelpers, type: :system
end
