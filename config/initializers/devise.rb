Devise.setup do |config|
  require 'devise/orm/active_record'

  config.mailer_sender = ->(_scope) { Rails.configuration.x.mail_from }
  config.case_insensitive_keys = [:email]
  config.strip_whitespace_keys = [:email]
  config.stretches = Rails.env.test? ? 1 : 12
  config.reset_password_within = 2.hours
  config.scoped_views = true
  config.sign_out_via = :delete
  config.responder.error_status = :unprocessable_content
  config.responder.redirect_status = :see_other
end
