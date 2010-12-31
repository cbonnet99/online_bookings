# Settings specified here will take precedence over those in config/environment.rb

# The production environment is meant for finished, "live" apps.
# Code is not reloaded between requests
config.cache_classes = true

# Full error reports are disabled and caching is turned on
config.action_controller.consider_all_requests_local = false
config.action_controller.perform_caching             = true
config.action_view.cache_template_loading            = true

# See everything in the log (default is :info)
# config.log_level = :debug

# Use a different logger for distributed setups
$:.unshift File.join(RAILS_ROOT, "vendor", "SyslogLogger-1.4.0", "lib")
require 'syslog_logger'
config.logger = RAILS_DEFAULT_LOGGER = SyslogLogger.new('colibri_staging')

# Use a different cache store in production
# config.cache_store = :mem_cache_store

# Enable serving of images, stylesheets, and javascripts from an asset server
config.action_controller.asset_host = "http://staging-assets%d.colibriapp.com"

# Disable delivery errors, bad email addresses will be ignored
# config.action_mailer.raise_delivery_errors = false
config.action_mailer.raise_delivery_errors = false
config.action_mailer.delivery_method = :test

# Enable threaded mode
# config.threadsafe!

config.after_initialize do
  ActiveMerchant::Billing::Base.mode = :test
  ::GATEWAY = ActiveMerchant::Billing::PaymentExpressGateway.new(
    :login => "BeAmazingDev",
    :password => "6229c3d7"
  )
end
