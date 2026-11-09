Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = ENV["CI"].present?
  config.consider_all_requests_local = true
  config.action_dispatch.show_exceptions = :none
  config.action_controller.allow_forgery_protection = false
  config.action_mailer.delivery_method = :test
end
