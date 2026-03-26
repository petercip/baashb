require "capybara/rspec"
require "capybara-playwright-driver"

# Register the Playwright driver as both default and JS driver.
Capybara.register_driver(:playwright) do |app|
  Capybara::Playwright::Driver.new(app, browser_type: :chromium, headless: true)
end

Capybara.default_driver    = :rack_test   # Fast driver for non-JS specs
Capybara.javascript_driver = :playwright  # Full browser for system specs tagged :js

# Match host to lvh.me for multi-tenant test routing.
Capybara.app_host = "http://baashb.lvh.me"
Capybara.server_host = "lvh.me"
Capybara.server_port = 3001
