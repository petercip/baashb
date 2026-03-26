require "spec_helper"
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
abort("The Rails environment is running in production mode!") if Rails.env.production?
require "rspec/rails"

# Auto-require all support files
Rails.root.glob("spec/support/**/*.rb").sort_by(&:to_s).each { |f| require f }

# Checks for pending migrations and applies them before tests are run.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  # Infer spec type from file location (spec/models → :model, spec/requests → :request, etc.)
  config.infer_spec_type_from_file_location!

  # Use transactional fixtures so each example runs in a rolled-back transaction.
  config.use_transactional_fixtures = true

  # Filter Rails gem lines from backtraces.
  config.filter_rails_from_backtrace!

  # FactoryBot shorthand: `create(:club)` instead of `FactoryBot.create(:club)`
  config.include FactoryBot::Syntax::Methods

  # Include URL helpers in all specs
  config.include Rails.application.routes.url_helpers

  # Time travel helpers (travel_to, freeze_time, etc.)
  config.include ActiveSupport::Testing::TimeHelpers

  # Reset Current attributes between examples so club/session/member don't leak.
  config.before(:each) do
    Current.reset
  end
end
