# Restart the server after changing this value. Existing signed cookies become invalid.
# Never reuse the signing secret published in this repository's history.
secret_token = ENV['SECRET_TOKEN']
if secret_token.nil? || secret_token.strip.length < 30
  raise 'Set SECRET_TOKEN to a unique random secret of at least 30 characters before starting conf-in'
end
ConfIn::Application.config.secret_token = secret_token
