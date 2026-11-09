require 'uri'

class UsersController < ApplicationController
  before_action :authenticate_user!, only: :send_qr

  def show
    @user = User.find(params[:id])
    @page_title = "#{@user.name} のプロフィール"
    @events = @user.events
  end

  def send_qr
    email = params[:email]
    if !email.is_a?(String) || !email.match?(/\A[^@\s]+@([^@.\s]+\.)+[^@.\s]+\z/)
      redirect_back_or_to root_path, alert: 'メールアドレスが不正です。', status: :see_other
    elsif deliver_mail(UserMailer.send_qr(current_user, email))
      redirect_back_or_to root_path, notice: 'QRコードを送信しました。', status: :see_other
    else
      redirect_back_or_to root_path, alert: 'QRコードの送信に失敗しました。', status: :see_other
    end
  end

  def icon
    user = User.find(params[:id])
    size = params[:size].to_s
    size = 'normal' unless %w[mini normal bigger].include?(size)

    icon_url = cached_icon_url(user, size)
    if icon_url
      redirect_to icon_url, allow_other_host: true
    else
      pixels = { 'mini' => 24, 'normal' => 48, 'bigger' => 73 }.fetch(size)
      redirect_to "/images/#{pixels}.png"
    end
  end

  private

  def cached_icon_url(user, size)
    return if user.tw_id.blank? || user.twicon_url.blank?

    uri = URI.parse(user.twicon_url)
    return unless uri.is_a?(URI::HTTP) && uri.host&.end_with?('.twimg.com') &&
      uri.userinfo.nil? && uri.port == uri.default_port

    uri = URI::HTTPS.build(host: uri.host, path: uri.path, query: uri.query)
    view_context.twicon_url_with_size(uri.to_s, size)
  rescue URI::InvalidURIError
    nil
  end
end
