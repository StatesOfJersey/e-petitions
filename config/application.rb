require File.expand_path('../boot', __FILE__)

require 'rails'

# Pick the frameworks you want:
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'action_view/railtie'
require 'sprockets/railtie'
require 'rails/test_unit/railtie'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Jpets
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.1

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'London'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :'en-GB'
    config.i18n.fallbacks = %i[en-GB]

    # Use SQL for the schema format
    config.active_record.schema_format = :sql

    # Configure the cache store
    config.cache_store = :mem_cache_store,
      ENV.fetch('MEMCACHE_SERVERS') { 'localhost:11211' }, {
        expires_in: 1.day, compress: true, race_condition_ttl: 10,
        namespace: ENV.fetch('MEMCACHE_NAMESPACE') { 'jpets' },
        pool_size: ENV.fetch('WEB_CONCURRENCY_MAX_THREADS') { 32 }.to_i
      }

    # Configure Active Record to use cache versioning
    config.active_record.cache_versioning = false

    # Configure Active Job queue adapter
    config.active_job.queue_adapter = :delayed_job

    # Remove the error wrapper from around the form element
    config.action_view.field_error_proc = -> (html_tag, instance) { html_tag }

    # Add additional exceptions to the rescue responses
    config.action_dispatch.rescue_responses.merge!(
      'Site::ServiceUnavailable' => :service_unavailable,
      'BulkVerification::InvalidBulkRequest' => :bad_request,
      'Admin::AccessDenied' => :forbidden
    )

    config.action_dispatch.default_headers.merge!('X-UA-Compatible' => 'IE=edge')
  end
end
