# coding: utf-8
class EventsController < ApplicationController
  #認証要求
  before_action :authenticate_user!, except: [:index, :show]
  
  # idによるイベント検索
  before_action :find_event, except: [:index, :new, :create, :destroy]
  
  # admin_tokenによる認証
  # ミス防止のために，フィルタしないものを指定
  before_action :authenticate_by_admin_token!,
    except: [
      :index, :show, :new, :create, :destroy, :resend_entry_mail
    ]
  
  # GET /events
  def index
    @events = Event.all
    @page_title = "イベント一覧"
  end

  # GET /events/1
  def show
    @page_title = @event.name
    #サブイベント取得（無いときnil）
    @sub_events = @event.sub_events
    #アクセスしたこのイベントにユーザが参加しているか
    @entry = current_user.entries.find_by(event: @event) if user_signed_in?
    #エントリー
    @entries = @event.entries
    #主催者の取得
    @owner_user = @event.owner_user
    #残り参加可能人数計算
    @remain = @event.capacity - @event.entries.count
    # 参加費用リスト
    @event_fees = @event.event_fees
    
    # 参加費用合計
    @entrysum = @entry.fees_sum if @entry

    #イベントの状態
    now = Time.current
    @status = if now < @event.joinable_period_begin then "準備中"
        elsif now < @event.joinable_period_end then "申込受付中"
        elsif now < @event.date then "申込受付終了"
        else "イベント終了"
      end

    #アクセスしているユーザ(ログインしている場合)
    @user = current_user
  end

  # GET /events/new
  def new
    @event = Event.new
    @page_title = "新規イベント作成"
    @event.owner_user_id = current_user.id
    
    # 1つ参加費用のフィールドを用意
    @event.event_fees.build
  end

  # POST /events
  def create
    @event = current_user.hosted_events.build(event_params)

    if @event.save
      redirect_to @event, notice: 'イベントは作成されました。', status: :see_other
    else
      @page_title = '新規イベント作成'
      render :new, status: :unprocessable_content
    end
  end

	# GET /events/:id/?admin_token=:admin_token
	def edit
		@page_title = "イベント編集 | #{@event.name}"

		@is_current_user_admin = current_user.id == @event.owner_user_id
	end

	# PUT /events/:id
	def update
    if @event.update(event_params)
      redirect_to @event, notice: 'イベントは編集されました。', status: :see_other
    else
      edit
      render :edit, status: :unprocessable_content
    end
	end


  # DELETE /events/:id
  def destroy
    #カレントユーザのホストイベントから検索
    @event = current_user.hosted_events.find(params[:id])

    #イベント削除
    @event.destroy!

    #トップページへリダイレクト
    redirect_to root_path, status: :see_other
  rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordNotDestroyed
    #失敗orアクセス権限なし
    #showページへリダイレクト
    redirect_to event_path(params[:id]), status: :see_other,
      notice: "イベント作成者以外はイベントを削除することはできません．"
  end

  # GET /events/:id/admin?admin_token=:admin_token
  # イベント管理者ページ
  # 機能としてはリンクページのみ
  def admin
  end
  
  # POST /events/:id/resend_entry_mail
  # 参加登録完了メール再送信
  def resend_entry_mail
    @entry = current_user.entries.find_by(event: @event)
    if @entry.nil?
      redirect_to @event, alert: 'あなたはこのイベントに参加していません．', status: :see_other
    elsif deliver_mail(EntryMailer.new_entry_user(@entry))
      redirect_to @event, notice: '参加登録完了メールが再送信されました．', status: :see_other
    else
      redirect_to @event, alert: '参加登録完了メールの送信に失敗しました。', status: :see_other
    end
  end

private

  def event_params
    survey_fields = (1..5).flat_map do |i|
      ["select#{i}", "select_content#{i}", "select_setting#{i}", "free#{i}", "free_setting#{i}"]
    end

    params.expect(event: [
      :name, :date, :summary, :website, :place_name, :place_address, :place_website,
      :capacity, :joinable_period_begin, :joinable_period_end, :hosting_group,
      :hosting_email, :main_event_id, :qr_use, *survey_fields,
      event_fees_attributes: [[:id, :name, :sum, :summary, :_destroy]]
    ])
  end
  # イベントIDからイベントを取得
  def find_event
    @event = Event.includes(:entries, :users).find(params[:id])
  end
  
  # イベント管理者ページのトークン認証
  def authenticate_by_admin_token!
    unless event_admin?
      redirect_to root_path, notice: '管理者トークンが間違っています。'
    end
  end
	
end

