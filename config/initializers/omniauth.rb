# OmniAuth — Google OAuth2 provider
#
# Credentials are per-environment. In development use Rails credentials:
#   rails credentials:edit --environment development
#   google_oauth2:
#     client_id: YOUR_ID
#     client_secret: YOUR_SECRET
#
# In production set GOOGLE_CLIENT_ID / GOOGLE_CLIENT_SECRET env vars
# (or use per-club OAuth apps once multi-club OAuth is needed).
#
# omniauth-rails_csrf_protection requires the initial /auth/:provider
# request to be a POST (button_to or form with method: :post).
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2,
           Rails.application.credentials.dig(:google_oauth2, :client_id)     || ENV["GOOGLE_CLIENT_ID"],
           Rails.application.credentials.dig(:google_oauth2, :client_secret) || ENV["GOOGLE_CLIENT_SECRET"],
           name:           "google",
           scope:          "email,profile",
           prompt:         "select_account",
           access_type:    "online",
           callback_path:  "/auth/google/callback"
end

OmniAuth.config.allowed_request_methods = %i[post]
OmniAuth.config.silence_get_warning     = true
