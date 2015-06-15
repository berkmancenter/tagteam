require File.expand_path('../boot', __FILE__)

require 'rails/all'

if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  Bundler.require(*Rails.groups(:assets => %w(development test)))
  # If you want your assets lazily compiled in production, use this line
  # Bundler.require(:default, :assets, Rails.env)
end

module Tagteam
  class Application < Rails::Application

    tagteam_config = YAML.load_file("#{Rails.root}/config/tagteam.yml")
    tagteam_config.keys.collect{|k| 
      Tagteam::Application.config.send("#{k}=", tagteam_config[k])
    }

    Sidekiq.configure_server do |sidekiq_config|
      sidekiq_config.redis = {
        namespace: config.redis_namespace,
        url: config.redis_host
      }
    end

    Sidekiq.configure_client do |sidekiq_config|
      sidekiq_config.redis = {
        namespace: config.redis_namespace,
        url: config.redis_host
      }
    end

    ActsAsTaggableOn.tags_counter = false

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    config.autoload_paths += %W(#{config.root}/lib)

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    config.active_record.observers = :feed_item_observer, :hub_feed_observer,
      :tag_filter_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'America/New_York'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password, :password_confirmation, 'SHARED_KEY_FOR_TASKS']

    # Enable the asset pipeline
    config.assets.enabled = true

    # Version of your assets, change this if you want to expire all your assets
    # config.assets.version = '1.0'

    config.active_record.whitelist_attributes = true

  end
end
