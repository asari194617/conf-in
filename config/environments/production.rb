Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true
  config.i18n.fallbacks = true
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")
  config.public_file_server.headers = { "cache-control" => "public, max-age=3600" }
end
