# coding: utf-8
require 'csv'
class EntriesController < ApplicationController
  # 認証要求
  before_action :authenticate_user!, except: [:qr_receive, :update, :index]
  
  # イベント情報を引っ張る
  before_action :find_event
  
  # admin_tokenによる認証
  # ミス防止のために，フィルタしないものを指定
  before_action :authenticate_by_admin_token!, only: [:index, :qr_receive, :update]
  
  # 定員に達したか？
  before_action :entries_filled, only: [:new, :confirm]
 
  # 受付期間内か？
  before_action :can_entry, only: [:new, :confirm, :destroy]
  
  # 既に参加しているかどうか
  before_action :already_has_joined, only: [:new, :confirm, :complete]
  
  # GET /entries/new
  # イベント参加登録
  def new
    @entry = @event.entries.build(user: current_user)
    @page_title = "イベントに参加 | #{@event.name}"
    
    # EventFeeを取得
    @event_fees = @event.event_fees
    @fee_ids = @entry.entry_fees.map{|f| f.event_fee_id}
  end
  
  # POST /entries/confirm
  # 参加登録内容の確認
  def confirm
    @entry = @event.entries.build(entry_params)
    @entry.user = current_user
    @page_title = "確認 | #{@event.name}"

    # EventFeeを取得
    @event_fees = @event.event_fees
    @fee_ids = @entry.entry_fees.map{|f| f.event_fee_id}

    
    if @entry.valid?
      render :confirm
    else
      render :new, status: :unprocessable_content
    end
  end

  # POST /entries/complete
  # 参加登録完了
  def complete
    @event.with_lock do
      can_entry
      entries_filled unless performed?
      unless performed?
        @entry = @event.entries.build(entry_params)
        @entry.user = current_user
        @entry.save
      end
    end
    return if performed?

    if @entry.persisted?
      @page_title = "参加登録完了 | #{@event.name}"
      @sub_events = @event.sub_events
      @entry_fees = @entry.entry_fees
      @entry_mail_sent = deliver_mail(EntryMailer.new_entry_user(@entry))
      flash.now[:alert] = '参加登録は完了しましたが、完了メールの送信に失敗しました。' unless @entry_mail_sent
      render :complete
    else
      @page_title = "イベントに参加 | #{@event.name}"
      @event_fees = @event.event_fees
      @fee_ids = @entry.entry_fees.map(&:event_fee_id)
      render :new, status: :unprocessable_content
    end
  end

  # PUT /entries/1
  # 当日受付情報の更新
  def update
    @entry = entries_for_qr_secret.find(params[:id])
    if params.key?(:entry)
      @entry.update!(params.expect(entry: [entry_fees_attributes: [[:id, :paid]]]))
    end

    if request.xhr?
      render partial: 'entry_fees_table'
    else
      redirect_to qr_receive_event_entries_path(@event, admin_token: @event.admin_token,
        qr_secret: @entry.user.qr_secret), status: :see_other
    end
  rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid
    if request.xhr?
      head :unprocessable_content
    else
      redirect_to root_path, alert: '受付情報の更新に失敗しました。', status: :see_other
    end
  end

  # DELETE /entries/1
  # 参加登録の解除
  def destroy
    #パラメータ
    @entry = current_user.entries.find_by!(id: params[:id], event: @event)

    #エントリー削除
    @entry.destroy!
    #イベントページへリダイレクト
    redirect_to event_path(@event),
      notice: '参加をキャンセルしました。', status: :see_other
  rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordNotDestroyed
    #トップページへリダイレクト
    redirect_to root_path,
      alert: 'キャンセルに失敗しました。', status: :see_other
  end
  
  
  # GET /events/:event_id/entries
  # イベント参加者一覧（管理者向け）
  # :event_idはadmin_tokenを使う
  # filterを通してイベント取得
  def index
    @page_title = "参加者一覧 | #{@event.name}"
    @entries = @event.entries

    respond_to do |format|
      format.html
      format.csv do
        output = CSV.generate(row_sep: "\r\n") do |csv|
          @event_fees = @event.event_fees

          # 参加費用名
          fee_name = @event_fees.map{|fee| fee.name}

          # 選択アンケートの項目名
          selects = (1..5).map{|i| @event.send("select#{i}")}

          # フリーアンケートの項目名
          free = (1..5).map{|i| @event.send("free#{i}")}

          # 1行目
          csv << [
            '登録日時',
            '登録名', 'Twitter ID', '職業', '勤務先・学校', 'コメント',
            fee_name, '合計参加費用',
            selects, free
          ].flatten

          @entries.each do |entry|
            # 参加費用ごとの徴収状況
            fees_paid = []
            @event_fees.each do |fee|
              if entry_fee = entry.entry_fees.find_by(event_fee_id: fee.id)
                fees_paid << (entry_fee.paid ? '済':'未')
              else
                fees_paid << ''
              end
            end
            # 選択アンケートの回答
            selects = (1..5).map{|i| entry.send("select#{i}")}
            # フリーアンケートの回答
            free = (1..5).map{|i| entry.send("free#{i}")}

            user = entry.user
            csv << [
              entry.created_at.strftime('%Y/%m/%d %H:%M:%S'),
              user.name, user.tw_id, user.job, user.office, entry.comment,
              fees_paid, entry.fees_sum,
              selects, free
            ].flatten
          end
        end
 
        send_data output.encode('Windows-31J', invalid: :replace, undef: :replace),
          type: 'text/csv; charset=Windows-31J',
          filename: "#{@event.id}(#{Time.current.strftime('%Y%m%d-%H%M')}).csv"
      end
    end
  end
  
  # 受付ページ
  def qr_receive
    @entry = entries_for_qr_secret.first!

    @page_title = "受付情報 | #{@event.name}"

  rescue ActiveRecord::RecordNotFound
    redirect_to root_path,
      alert: 'QRコードが間違っている、あるいは参加登録がされていません。'
  end

private
  def entry_params
    survey_fields = (1..5).flat_map { |i| ["select#{i}", "free#{i}"] }
    params.expect(entry: [:comment, *survey_fields, entry_fees_attributes: [[:event_fee_id]]])
  end

  def entries_for_qr_secret
    secret = params[:qr_secret]
    return @event.entries.none unless secret.is_a?(String) && secret.present?

    @event.entries.joins(:user).where(users: { qr_secret: secret })
  end

  # パラメータからイベントを取得
  def find_event
    @event_id = params[:event_id]
    unless @event_id
      return redirect_to(events_path, 
                         alert: 'イベントは削除されたもしくは存在しません。')
    end
    @event = Event.find(@event_id)
    
    @select_form = [
      { :answer => :select1,
        :question => @event.select1,
        :content => @event.select_content1,
        :setting => @event.select_setting1 },
      { :answer => :select2,
        :question => @event.select2,
        :content => @event.select_content2,
        :setting => @event.select_setting2 },
      { :answer => :select3,
        :question => @event.select3,
        :content => @event.select_content3,
        :setting => @event.select_setting3 },
      { :answer => :select4,
        :question => @event.select4,
        :content => @event.select_content4,
        :setting => @event.select_setting4 },
      { :answer => :select5,
        :question => @event.select5,
        :content => @event.select_content5,
        :setting => @event.select_setting5 }
    ]
    @free_form = [
      { :answer => :free1,
        :question => @event.free1,
        :setting => @event.free_setting1 },
      { :answer => :free2,
        :question => @event.free2,
        :setting => @event.free_setting2 },
      { :answer => :free3,
        :question => @event.free3,
        :setting => @event.free_setting3 },
      { :answer => :free4,
        :question => @event.free4,
        :setting => @event.free_setting4 },
      { :answer => :free5,
        :question => @event.free5,
        :setting => @event.free_setting5 }
    ]
  end

  # 定員に達したか？
  def entries_filled
    if @event.entries.count >= @event.capacity
      redirect_to @event,
        alert: '既に定員に達しています。', status: :see_other
    end
  end
  
  # 受付期間内か？
  def can_entry
    unless Time.current.between?(@event.joinable_period_begin, @event.joinable_period_end)
      redirect_to @event,
        alert: '参加登録期間は開始していない、もしくは終了しています。', status: :see_other
    end
  end
  
  # イベント管理者ページのトークン認証
  def authenticate_by_admin_token!
    unless event_admin?
      if request.xhr?
        head :forbidden
      else
        redirect_to root_path, alert: 'アクセス権限がありません。', status: :see_other
      end
    end
  end

  # 既に参加しているかどうか
  def already_has_joined
    if @event.entries.exists?(user: current_user)
      redirect_to @event, alert: 'あなたは既にこのイベントに参加しています。', status: :see_other
    end
  end

end
