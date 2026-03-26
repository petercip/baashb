# FactoryBot lint: verify all factories produce valid records at boot.
# Wrapped in a transaction so the DB stays clean after lint.
RSpec.configure do |config|
  config.before(:suite) do
    FactoryBot.lint
  end
end
