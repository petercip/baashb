require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# ClubMiddleware must be required explicitly here because config/application.rb
# is loaded before Rails autoloading is active.
require_relative "../app/middleware/club_middleware"

module Baashb
  class Application < Rails::Application
    config.load_defaults 8.1

    config.autoload_lib(ignore: %w[assets tasks])

    # ClubMiddleware: resolves Current.club from Host header before session processing.
    # Must run before ActionDispatch::Session so the club context is available
    # during cookie-based session resumption.
    config.middleware.insert_before ActionDispatch::Session::CookieStore, ClubMiddleware

    # Time zone
    config.time_zone = "UTC"
  end
end
