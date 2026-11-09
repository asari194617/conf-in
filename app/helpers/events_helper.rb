module EventsHelper
  def form_url
    if @event.persisted?
      event_path(@event, admin_token: @event.admin_token)
    else
      events_path
    end
  end

  def link_to_destroy_event(label = 'このイベントを削除する', html_options = {})
    return unless current_user && @event.owner_user_id == current_user.id

    button_to label, event_path(@event), method: :delete,
      form: { data: { confirm: '本当に削除しますか？（ユーザからの参加登録も同時に削除されます）' } },
      **html_options
  end

  def link_to_edit_event(label = 'このイベントを編集する', html_options = {})
    link_to label, edit_event_path(@event, admin_token: @event.admin_token), html_options
  end
end
