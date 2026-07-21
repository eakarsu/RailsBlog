require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_view/railtie"
require "sprockets/railtie"

Bundler.require(*Rails.groups)

module Blog2
  class Application < Rails::Application
    config.load_defaults 8.1
    config.time_zone = "UTC"
    config.active_record.default_timezone = :utc
    config.filter_parameters += %i[password password_confirmation token email ip_address body file]
    config.action_dispatch.cookies_same_site_protection = :lax
    config.active_storage.variant_processor = :disabled
    config.active_storage.draw_routes = false
  end
end
