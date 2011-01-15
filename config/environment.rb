# Be sure to restart your server when you modify this file

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.4' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.

  # Add additional load paths for your own custom dirs
  config.load_paths += %W( #{RAILS_ROOT}/app/behaviors )

  # Specify gems that this application depends on and have them installed with rake gems:install
  # config.gem "bj"
  # config.gem "hpricot", :version => '0.6', :source => "http://code.whytheluckystiff.net"
  # config.gem "sqlite3-ruby", :lib => "sqlite3"
  # config.gem "aws-s3", :lib => "aws/s3"
  config.gem "thoughtbot-factory_girl",
               :lib    => "factory_girl",
               :source => "http://gems.github.com"
  config.gem 'icalendar'
  config.gem 'geoip'
  config.gem 'whenever', :lib => false, :source => 'http://gemcutter.org/'
  config.gem 'aasm', :source => "http://gemcutter.org"
  config.gem 'ambethia-smtp-tls', :lib => "smtp-tls", :source => "http://gems.github.com"
  config.gem 'active_merchant'
  config.gem 'clickatell'
  config.gem 'will_paginate'
  
  # Only load the plugins named here, in the order given (default is alphabetical).
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Skip frameworks you're not going to use. To use Rails without a database,
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

  # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
  # Run "rake -D time" for a list of tasks for finding time zone names.
  config.time_zone = 'Paris'
  
  # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
   config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}')]
   config.i18n.default_locale = :fr

  config.action_mailer.smtp_settings = {
      :enable_starttls_auto => true,
      :address        => 'smtp.gmail.com',
      :port           => 587,
      :domain         => 'gmail.com',
      :authentication => :plain,
      :user_name      => 'colibriapp@gmail.com',
      :password       => 'mavslr55'
  }
  config.after_initialize do
    require 'smtp-tls'
  end
  
end

ExceptionNotification::Notifier.exception_recipients = %w(cbonnet99@gmail.com)
ExceptionNotification::Notifier.sender_address = %("Colibri Error" <colibriapp@gmail.com>)
ExceptionNotification::Notifier.email_prefix = "[Colibri] "

#add support for choice in Ruby versions that don't support it (1.8.6)
unless Array.instance_methods.include_method? :choice
  Array.class_eval do
    def choice
      self[self.size.rand]
    end
  end
end
module ActiveSupport
   class TimeWithZone
     
     def day_and_time
       "#{self.strftime('%A %d %B %Y')} at #{self.simple_time}"
     end
     
     def simple_time
       minutes = self.strftime("%M")
       hours = self.strftime("%l")
       am_pm = self.strftime("%p")
       hours_separator = I18n.t(:hours_separator, :scope=>[:time])
       hours_marker = I18n.t(:hours_marker, :scope=>[:time])
       if minutes == "00"
         if hours_marker.blank?
           "#{hours}#{am_pm.downcase}"
         else
           "#{hours}#{hours_marker}"
         end
       else
         if hours_marker.blank?
           "#{hours}#{hours_separator}#{minutes}#{am_pm.downcase}"
         else
           "#{hours}#{hours_marker}#{minutes}"
         end
       end
     end
     
     def js_args
       year = self.strftime("%Y").to_i
       #in Javascript, month count starts at 0!!!
       month = (self.strftime("%m").to_i-1)
       day = self.strftime("%d").to_i
       hour = self.strftime("%H").to_i
       min = self.strftime("%M").to_i
       sec = self.strftime("%S").to_i
       [year, month, day, hour, min, sec].map(&:to_s).join(",")
     end
   end
 end

