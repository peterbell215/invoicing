# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'spec_helper'

ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'

# Require any support files.
Dir[Rails.root.join('spec/support/**/*.rb')].sort.each { |f| require f }
require 'rspec/rails'

# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?

# Add additional requires below this line. Rails is not loaded until this point!
require "capybara/rails"
require "capybara/rspec"
require "clearance/rspec"

require 'action_view/helpers/number_helper'
require 'action_view/record_identifier'

# Checks for pending migrations and applies them before tests are run.
# If you are not using ActiveRecord, you can remove these lines.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  puts e.to_s.strip
  exit 1
end

RSpec.configure do |config|
  # setup for factory bot
  config.include FactoryBot::Syntax::Methods
  config.include Rails.application.routes.url_helpers
  config.include Rails.application.routes.mounted_helpers
  config.include ActionView::RecordIdentifier

  config.before(:each) do
    FactoryBot.rewind_sequences
  end

  config.before(:each, type: :system) do |example|
    if example.metadata[:js]
      driven_by :selenium_chrome
    else
      driven_by :selenium_chrome_headless
    end

    user ||= FactoryBot.create(:user)
    visit root_path(as: user)
  end

  # DatabaseCleaner setup
  config.use_transactional_fixtures = false

  config.before(:suite) do
    if config.use_transactional_fixtures?
      raise(<<-MSG)
        Delete line `config.use_transactional_fixtures = true` from rails_helper.rb
        (or set it to false) to prevent uncommitted transactions being used in
        JavaScript-dependent specs.

        During testing, the app-under-test that the browser driver connects to
        uses a different database connection to the database connection used by
        the spec. The app's database connection would not be able to access
        uncommitted transaction data setup over the spec's database connection.
      MSG
    end
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each, type: :system) do
    # :rack_test driver's Rack app under test shares database connection
    # with the specs, so continue to use transaction strategy for speed.
    driver_shares_db_connection_with_specs = Capybara.current_driver == :rack_test

    unless driver_shares_db_connection_with_specs
      # Driver is probably for an external browser with an app
      # under test that does *not* share a database connection with the
      # specs, so use truncation strategy.
      DatabaseCleaner.strategy = :truncation
    end
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.append_after(:each) do
    DatabaseCleaner.clean
  end
end
