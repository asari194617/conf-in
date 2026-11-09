# coding: utf-8
class UserMailer < ActionMailer::Base
  include ApplicationHelper

  default from: -> { Rails.configuration.x.mail_from }

  def send_qr(user,email)
    @user = user
    
    # QRコードの添付
    # 添付ファイル
    attachments["#{@user.id}.png"] = qr_png_binary(@user.qr_secret)

    mail to: email,
      subject: "[カンファイン]当日受付QRコード"
  end
end
