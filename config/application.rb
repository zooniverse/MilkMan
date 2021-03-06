require File.expand_path('../boot', __FILE__)

# Pick the frameworks you want:
# require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "rails/test_unit/railtie"
require 'sprockets/railtie'

require 'yaml'
require 'csv'

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env) if defined?(Bundler)

module Milkman
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # JavaScript files you want as :defaults (application.js is always included).
    # config.action_view.javascript_expansions[:defaults] = %w(jquery rails)

    # config.assets.enabled = true

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    config.generators do |g|
      g.orm :mongo_mapper
    end

    config.after_initialize do
        Subject.ensure_index [[:coords, 1]], :sparse => true
        Subject.ensure_index [[:zooniverse_id, 1]], :sparse => true
        Subject.ensure_index [['group.zooniverse_id', 1]], :sparse => true
        Subject.ensure_index [['metadata.has_illustrations_count', 1]], :sparse => true
        Subject.ensure_index [['metadata.page_id', 1]], :sparse => true
        Subject.ensure_index [[:state, 1]], :sparse => true
        Classification.ensure_index [[:subject_ids, 1]], :sparse => true
        ScanResult.ensure_index [[:zooniverse_id, 1]], :sparse => true
        ScanResult.ensure_index [[:state, 1]], :sparse => true
        ScanResult.ensure_index [[:eps, 1]], :sparse => true
        ScanResult.ensure_index [[:min, 1]], :sparse => true
    end

    config.assets.precompile += %w( bootstrap.css dc.css explore.css main.css mwp-styles.css subjects.css welcome.css )
    config.assets.precompile += %w( bootstrap.min.js crossfilter.js d3.js dc.js explore.js jquery.1.9.1.min.js jquery.svg.min.js subjects.js welcome.js )

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]
  end
end
