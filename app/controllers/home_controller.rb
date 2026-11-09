class HomeController < ApplicationController
  def index
    #向こう１週間で参加登録が終了するイベント
    now = Time.current
    @near_closing_events = Event.where(joinable_period_end: now..(now + 7.days))
      .order(joinable_period_end: :desc).limit(5)

		#開催されるイベント
    @near_events = Event.where(date: now..).order(date: :desc).limit(5)
	end
	
	def about
	end
end
