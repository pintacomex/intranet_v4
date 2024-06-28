require File.expand_path('../boot', __FILE__)

require 'rails/all'
require 'csv'

require 'barby'
require 'barby/barcode/qr_code'
require 'barby/outputter/prawn_outputter'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env)

module R4a
  class Application < Rails::Application

    # don't generate RSpec tests for views and helpers
    config.generators do |g|

      g.test_framework :rspec, fixture: true
      g.fixture_replacement :factory_girl, dir: 'spec/factories'


      g.view_specs false
      g.helper_specs false
    end

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'Mexico City'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '*.{rb,yml}').to_s]
    config.i18n.enforce_available_locales = false
    config.i18n.default_locale = :en
  end
end

Raven.configure do |config|
  # config.dsn = 'https://8c3e28f8c4a644f4becc6e7a11a69d78:3e40f6d88a4e4f948028ab7ce107867e@sentry.io/187188'
  config.dsn = 'https://e1c9fcb142454ce5a6cc39fae32d0f38:7b14bdde7c4845da911821064ba91e20@sentry.io/197884'  
end