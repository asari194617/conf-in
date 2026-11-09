require_relative "boot"

require "rails"
require "active_record/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require "action_mailer/railtie"
require "active_job/railtie"
require "rails/test_unit/railtie"

Bundler.require(*Rails.groups)

module ConfIn
  class Application < Rails::Application
    config.load_defaults 8.1

    config.time_zone = "Tokyo"
    config.i18n.default_locale = :ja
    config.i18n.available_locales = [:ja, :en]
    config.filter_parameters += %i[password token secret]

    config.session_store :active_record_store, key: "_conf_in_session", secure_session_only: true
    config.active_record.dump_schema_after_migration = false

    config.x.contact_email = ENV["GMAIL_USER"].presence
    config.x.mail_from = config.x.contact_email || "conf-in@example.test"
    config.action_mailer.default_url_options = {
      host: ENV.fetch("APP_HOST", "localhost:3000"),
      protocol: ENV.fetch("APP_PROTOCOL", Rails.env.production? ? "https" : "http")
    }
    config.action_mailer.raise_delivery_errors = true

    if ENV["GMAIL_USER"].present? && ENV["GMAIL_PASSWORD"].present?
      config.action_mailer.delivery_method = :smtp
      config.action_mailer.smtp_settings = {
        address: "smtp.gmail.com",
        port: 587,
        domain: ENV.fetch("GMAIL_DOMAIN", "localhost"),
        user_name: ENV["GMAIL_USER"],
        password: ENV["GMAIL_PASSWORD"],
        authentication: :plain,
        enable_starttls: true
      }
    else
      config.action_mailer.delivery_method = :file
      config.action_mailer.file_settings = { location: Rails.root.join("tmp/mail") }
    end
  end
end
