source "https://rubygems.org"

gem "rails", "~> 8.1.3"
gem "propshaft"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "jbuilder"

# Asset caching / compression
gem "thruster", require: false

# Database-backed adapters for cache, jobs, and cable
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Image variants (Active Storage)
gem "image_processing", "~> 1.2"

# S3-compatible object storage (Active Storage → Hetzner Object Storage)
gem "aws-sdk-s3", require: false

# Password hashing (has_secure_password)
gem "bcrypt", "~> 3.1"

# Pretty URLs (slug-based)
gem "friendly_id", "~> 5.5"

# Payments
gem "stripe", "~> 13.0"

# Calendar invites
gem "icalendar"

# Auth: Google OAuth
gem "omniauth-google-oauth2", "~> 1.1"
gem "omniauth-rails_csrf_protection"

# Rate limiting
gem "rack-attack"

# Boot time caching
gem "bootsnap", require: false

# Deploy
gem "kamal", require: false

# Windows / JRuby timezone data
gem "tzinfo-data", platforms: %i[ windows jruby ]

group :development do
  gem "web-console"
  gem "letter_opener"  # preview emails in browser during development
end

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
  gem "bundler-audit", require: false

  gem "rspec-rails", "~> 8.0"
  gem "factory_bot_rails"
end

group :test do
  gem "capybara"
  gem "capybara-playwright-driver"
  gem "shoulda-matchers", "~> 7.0"
  gem "webmock"           # stub external HTTP (Stripe, SMTP) in tests
end
