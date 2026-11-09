# coding: utf-8
class EventMailsController < ApplicationController
  before_action :find_event

  # admin_tokenによる認証
  before_action :authenticate_by_admin_token!
  
  # GET /events/:event_id/event_mails
  # 送信済みメール一覧
  def index
    @mails = @event.event_mails
    @page_title = "メール送信履歴 | #{@event.name}"
  end

  # GET /events/:event_id/event_mails/:id
  # メールの内容
  def show
    @mail = @event.event_mails.find(params[:id])
    @page_title = "#{@mail.subject} | メール送信履歴 | #{@event.name}"
  end

  # GET /events/:event_id/event_mails/new
  # 新規メール
  def new
    @mail = @event.event_mails.new

    @page_title = "新規メール送信 | #{@event.name}"
  end

  # POST /events/:event_id/event_mails
  # 送信確認
  def confirm
    @mail = @event.event_mails.build(params.expect(event_mail: [:subject, :text]))
    @page_title = "確認 | 新規メール送信 | #{@event.name}"
    
    if @mail.valid?
      session[:event_mail] = { 'event_id' => @event.id, 'subject' => @mail.subject, 'text' => @mail.text }
      
      render :confirm
    else
      session.delete(:event_mail)
      flash.now[:alert] = '入力に誤りがあります。確認してください。'
      render :new, status: :unprocessable_content
    end
  end
  
  # POST /events/:event_id/event_mails
  # 送信
  def create
    draft = session[:event_mail]
    if draft.nil? || draft['event_id'] != @event.id
      return redirect_to new_event_event_mail_path(@event, admin_token: @event.admin_token),
        alert: 'メールの送信内容を確認してください。', status: :see_other
    end

    session.delete(:event_mail)
    @mail = @event.event_mails.build(draft.slice('subject', 'text'))
    sent = EventMail.transaction do
      @mail.save!
      raise ActiveRecord::Rollback unless deliver_mail(EventMailer.all_entry_users(@mail))
      true
    end

    if sent
      redirect_to event_event_mail_path(@event, @mail, admin_token: @event.admin_token),
        notice: 'メールは送信されました。', status: :see_other
    else
      @page_title = "新規メール送信 | #{@event.name}"
      flash.now[:alert] = 'メールを送信できませんでした。もう一度お試しください。'
      render :new, status: :service_unavailable
    end
  end

private
  # イベントオブジェクトの取得
  def find_event
    @event = Event.find(params[:event_id])
  end
  
  # イベント管理者ページのトークン認証
  def authenticate_by_admin_token!
    unless event_admin?
      redirect_to root_path,
        notice: 'イベント管理者認証に失敗しました．'
    end
  end
end
