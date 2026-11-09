# coding: utf-8
class Entry < ActiveRecord::Base

  #イベント
  belongs_to :event
  #参加ユーザ
  belongs_to :user

  # 参加費
  has_many :entry_fees, dependent: :delete_all
	has_many :event_fees, through: :entry_fees

  # 参加費フォーム
  # 名前と金額が空なら削除
  accepts_nested_attributes_for :entry_fees,
    reject_if: ->(fee) { fee[:id].blank? && fee[:event_fee_id].blank? }
  
  #空の値をはじく
  validates_presence_of :event_id, :user_id,
    :message => "は必須項目です。"
  #ユーザ名が一意になるように
  validates_uniqueness_of :user_id,
    :scope => "event_id", #イベント内で一意
    :message => "あなたは既にこのイベントに参加登録しています。"

  #ひと言の文字数制限
  validates_length_of :comment, :maximum => 30

  #アンケートの設定に応じた必須項目の設定
  (1..5).each do |i|
    validates :"select#{i}", presence: true, on: :create,
      if: -> { event&.public_send("select_setting#{i}") == 2 }
    validates :"free#{i}", presence: true, on: :create,
      if: -> { event&.public_send("free_setting#{i}") == 2 }
  end

  validate :fees_belong_to_event, on: :create

  #フリーアンケートの文字数制限
  validates_length_of :free1, :maximum => 400, :allow_nil => true
  validates_length_of :free2, :maximum => 400, :allow_nil => true
  validates_length_of :free3, :maximum => 400, :allow_nil => true
  validates_length_of :free4, :maximum => 400, :allow_nil => true
  validates_length_of :free5, :maximum => 400, :allow_nil => true

  # receivedの整形
  def received_to_s
    i = self.received || 0
    %w(未確認 出席 欠席)[i]
  end


	# 参加費用の合計
	def fees_sum
		event_fees.sum(:sum)
	end

  private

  def fees_belong_to_event
    fees = entry_fees.map(&:event_fee)
    if fees.any? { |fee| fee.nil? || fee.event_id != event_id } || fees.uniq.size != fees.size
      errors.add(:entry_fees, 'に無効な参加費用が含まれています。')
    end
  end
end
