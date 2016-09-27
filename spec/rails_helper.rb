# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'spec_helper'
require 'rspec/rails'
require 'capybara/rspec'
require 'simple_bdd'
require 'shoulda/matchers'
require 'pundit/rspec'
include Warden::Test::Helpers
Warden.test_mode!
# Add additional requires below this line. Rails is not loaded until this point!

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
# Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

# Checks for pending migration and applies them before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  config.include SimpleBdd, type: :feature
  # config.include Devise::TestHelpers, :type => :controller
  config.before(:suite) do
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.clean_with(:truncation)
  end


  Capybara.javascript_driver = :webkit
  
  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end

  config.include Warden::Test::Helpers
  config.before :suite do
    Warden.test_mode!
  end


  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    # Choose a test framework:
    with.test_framework :rspec
    # Choose one or more libraries:
    with.library :rails
  end
end

Geocoder.configure(:lookup => :test)

Geocoder::Lookup::Test.set_default_stub(
  [
    {
      'latitude' => 51.04,
      'longitude' => 3.71,
      'address' => 'Gent, Oost-Vlaanderen',
      'country' => 'BE'
    }
  ]
)

OmniAuth.config.test_mode = true
OmniAuth.config.mock_auth[:stripe_connect] =
OmniAuth::AuthHash.new({
 provider: "stripe",
 uid: "123545",
 credentials: {
   token: "13123123123"
 },
 info: {
   stripe_publishable_key: "123123123123"
 }
})

Capybara::Webkit.configure do |config|
  config.allow_url("csi.gstatic.com")
  config.allow_url("http://csi.gstatic.com/csi?v=2&s=mapsapi3&v3v=24.13&action=map2&firstmap=true&hdpi=false&mob=false&staticmap=true&size=800x400&hadviewport=true&rt=visreq.63")
  config.allow_url("https://js.stripe.com/v2/")
  config.allow_url("maps.googleapis.com")
  config.allow_url("api.stripe.com")
  config.allow_url("maps.google.com")
  config.allow_url("maps.gstatic.com")
  config.allow_url("fonts.googleapis.com")
end

