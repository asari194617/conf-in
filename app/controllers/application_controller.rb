require 'net/smtp'

class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?
  $select_form = [
    { question: :select1, content: :select_content1,
      setting: :select_setting1 },
    { question: :select2, content: :select_content2,
      setting: :select_setting2 },
    { question: :select3, content: :select_content3,
      setting: :select_setting3 },
    { question: :select4, content: :select_content4,
      setting: :select_setting4 },
    { question: :select5, content: :select_content5,
      setting: :select_setting5 }
  ]
  $free_form = [
    { question: :free1, setting: :free_setting1 },
    { question: :free2, setting: :free_setting2 },
    { question: :free3, setting: :free_setting3 },
    { question: :free4, setting: :free_setting4 },
    { question: :free5, setting: :free_setting5 }
  ]
  
  protect_from_forgery with: :exception

  private

  def configure_permitted_parameters
    profile_fields = %i[name memo website job office domicile tw_id]
    devise_parameter_sanitizer.permit(:sign_up, keys: profile_fields)
    devise_parameter_sanitizer.permit(:account_update, keys: profile_fields)
  end

  def event_admin?
    token = params[:admin_token]
    @event.admin_token.present? && token.is_a?(String) &&
      ActiveSupport::SecurityUtils.secure_compare(@event.admin_token, token)
  end

  def deliver_mail(message)
    message.deliver_now
    true
  rescue Net::SMTPError, Net::ProtocolError, Timeout::Error, SocketError,
         SystemCallError, IOError, OpenSSL::SSL::SSLError => error
    logger.warn("Mail delivery failed (#{error.class})")
    false
  end
end
