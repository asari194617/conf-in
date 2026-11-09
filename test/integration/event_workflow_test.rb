require "test_helper"
require "csv"

class EventWorkflowTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  setup do
    @owner = User.create!(name: "主催者", email: "owner@example.test", password: "test-password")
    @attendee = User.create!(name: "参加者", email: "attendee@example.test", password: "test-password")
  end

  test "public pages show an upcoming event and the host can create, edit and delete it" do
    get new_event_path
    assert_redirected_to new_user_session_path
    log_in @owner

    get new_event_path
    assert_response :success
    assert_select 'form input[name="event[name]"]'
    assert_no_difference "Event.count" do
      post events_path, params: { event: { name: "必要な項目がないイベント" } }
      assert_response 422
    end

    assert_difference ["Event.count", "EventFee.count"], 1 do
      post events_path, params: {
        event: event_attributes.merge(owner_user_id: @attendee.id, admin_token: "forged",
                                      event_fees_attributes: { "0" => { name: "参加費", sum: 1200 } })
      }
    end
    event = @owner.hosted_events.find_by!(name: "長岡カンファレンス")
    assert_redirected_to event_path(event)
    assert_not_equal "forged", event.admin_token
    assert_equal 1200, event.event_fees.first.sum

    get admin_event_path(event, admin_token: "incorrect")
    assert_response :redirect
    get admin_event_path(event, admin_token: event.admin_token)
    assert_response :success
    assert_select "a[href=?]", event_entries_path(event, admin_token: event.admin_token)

    get edit_event_path(event, admin_token: event.admin_token)
    assert_response :success
    patch event_path(event, admin_token: event.admin_token), params: {
      event: { name: "長岡カンファレンス（更新）",
               event_fees_attributes: { "0" => { id: event.event_fees.first.id, sum: 1500 } } }
    }
    assert_redirected_to event_path(event)
    assert_equal 1500, event.event_fees.first.sum

    delete destroy_user_session_path
    [root_path, events_path, event_path(event)].each do |path|
      get path
      assert_response :success
      assert_includes response.body, "長岡カンファレンス（更新）"
    end
    [about_path, help_path].each do |path|
      get path
      assert_response :success
    end

    log_in @attendee
    assert_no_difference "Event.count" do
      delete event_path(event)
      assert_response :redirect
    end
    delete destroy_user_session_path

    log_in @owner
    assert_difference "Event.count", -1 do
      delete event_path(event)
      assert_redirected_to root_path
    end
  end

  test "confirm and complete an entry with survey answers and fees, resend its ticket, then cancel" do
    event = create_event
    fee = event.event_fees.create!(name: "会場費", sum: 1200)
    log_in @attendee

    get new_event_entry_path(event)
    assert_response :success
    assert_select 'form [name="entry[select1]"]'
    assert_select 'form textarea[name="entry[free1]"]'

    assert_no_difference "Entry.count" do
      post confirm_event_entries_path(event), params: { entry: { comment: "楽しみです" } }
      assert_response 422
    end

    entry_params = { select1: "現地", free1: "質問への回答", comment: "楽しみです",
                     entry_fees_attributes: { "0" => { event_fee_id: fee.id } } }
    assert_no_difference "Entry.count" do
      post confirm_event_entries_path(event), params: { entry: entry_params }
      assert_response :success
      assert_includes response.body, "質問への回答"
      assert_includes response.body, "会場費"
    end

    messages = capture_emails do
      assert_difference "Entry.count", 1 do
        post complete_event_entries_path(event), params: { entry: entry_params }
      end
      assert_response :success
      assert_includes response.body, "参加登録完了"
    end
    assert_equal 1, messages.size
    assert_equal [@attendee.email], messages.first.to
    assert_equal "image/png", messages.first.attachments.first.mime_type

    entry = event.entries.find_by!(user: @attendee)
    assert_equal 1200, entry.fees_sum
    assert_equal "現地", entry.select1
    assert_equal "質問への回答", entry.free1

    assert_no_difference "Entry.count" do
      post complete_event_entries_path(event), params: { entry: entry_params }
      assert_redirected_to event_path(event)
    end

    get user_path(@attendee)
    assert_response :success
    assert_select 'a[href=?]', event_path(event)

    get event_path(event)
    assert_response :success
    assert_select 'img[src^="data:image/"]'

    assert_emails 1 do
      post resend_entry_mail_event_path(event)
      assert_redirected_to event_path(event)
    end

    assert_difference "Entry.count", -1 do
      delete event_entry_path(event, entry)
      assert_redirected_to event_path(event)
    end
    assert_empty EntryFee.where(entry_id: entry.id)
  end

  test "reject registration outside its time window and when the event is full" do
    closed = create_event(name: "受付終了", joinable_period_begin: 3.days.ago, joinable_period_end: 1.day.ago)
    full = create_event(name: "満席", capacity: 1)
    full.entries.create!(user: @owner, select1: "現地", free1: "質問への回答")
    log_in @attendee

    [closed, full].each do |event|
      assert_no_difference "Entry.count" do
        post complete_event_entries_path(event), params: { entry: { select1: "現地", free1: "回答" } }
        assert_redirected_to event_path(event)
      end
    end
  end

  test "use the admin token to list entries, check in a participant, and export Japanese CSV" do
    event = create_event
    fee = event.event_fees.create!(name: "参加費", sum: 1000)
    entry = event.entries.create!(user: @attendee, select1: "現地", free1: "質問への回答")
    charge = entry.entry_fees.create!(event_fee: fee)
    admin = { admin_token: event.admin_token }
    check_in = admin.merge(qr_secret: @attendee.qr_secret)

    get event_entries_path(event)
    assert_response :redirect
    get event_entries_path(event, **admin)
    assert_response :success
    assert_select "a[href=?]", qr_receive_event_entries_path(event, **check_in)

    get qr_receive_event_entries_path(event, **admin, qr_secret: "invalid")
    assert_response :redirect
    get qr_receive_event_entries_path(event, **check_in)
    assert_response :success
    assert_select "h1", text: /長岡カンファレンス.*受付/
    assert_includes response.body, "未領収"

    patch event_entry_path(event, entry, **check_in), params: {
      entry: { entry_fees_attributes: { "0" => { id: charge.id, event_fee_id: fee.id, paid: "1" } } }
    }
    assert_redirected_to qr_receive_event_entries_path(event, **check_in)
    assert charge.reload.paid?
    follow_redirect!
    assert_response :success
    assert_includes response.body, "領収済"

    get event_entries_path(event, format: :csv, **admin)
    assert_response :success
    assert_equal "text/csv", response.media_type
    csv = CSV.parse(response.body.dup.force_encoding("Windows-31J").encode("UTF-8"), headers: true)
    assert_equal "参加者", csv.first["登録名"]
    assert_equal "済", csv.first["参加費"]
    assert_equal "1000", csv.first["合計参加費用"]
    assert_equal "質問への回答", csv.first["自由回答"]
  end

  test "confirm and send a bulk email at the body length limit and keep a sent history" do
    event = create_event
    event.entries.create!(user: @attendee, select1: "現地", free1: "質問への回答")
    admin = { admin_token: event.admin_token }
    log_in @owner

    get event_event_mails_path(event)
    assert_response :redirect
    get event_event_mails_path(event, **admin)
    assert_response :success
    get new_event_event_mail_path(event, **admin)
    assert_response :success

    assert_no_difference "EventMail.count" do
      post confirm_event_event_mails_path(event, **admin), params: { event_mail: { subject: "", text: "" } }
      assert_response 422
    end

    body = "入口に受付があります。".ljust(1998, "案内") + "以上"
    draft = { subject: "会場のご案内", text: body }
    assert_no_emails do
      assert_no_difference "EventMail.count" do
        post confirm_event_event_mails_path(event, **admin), params: { event_mail: draft }
      end
    end
    assert_response :success
    assert_includes response.body, body

    messages = capture_emails do
      assert_difference "EventMail.count", 1 do
        post event_event_mails_path(event, **admin)
      end
    end
    assert_equal 1, messages.size
    assert_equal [@attendee.email], messages.first.bcc
    assert_equal [@owner.email], messages.first.to
    assert_includes messages.first.body.decoded, body

    record = event.event_mails.find_by!(subject: "会場のご案内")
    assert_redirected_to event_event_mail_path(event, record, **admin)
    follow_redirect!
    assert_response :success
    assert_includes response.body, body
    get event_event_mails_path(event, **admin)
    assert_response :success
    assert_select "a", text: "会場のご案内"

    assert_no_emails do
      assert_no_difference "EventMail.count" do
        post event_event_mails_path(event, **admin)
      end
    end
    assert_response :redirect
  end

  private

  def log_in(user)
    post user_session_path, params: { user: { email: user.email, password: "test-password" } }
    assert_response :redirect
  end

  def create_event(**overrides)
    @owner.hosted_events.create!(event_attributes.merge(overrides))
  end

  def event_attributes
    {
      name: "長岡カンファレンス", date: 7.days.from_now, place_name: "長岡高専",
      place_address: "長岡市西片貝町", capacity: 20, joinable_period_begin: 1.day.ago,
      joinable_period_end: 3.days.from_now, hosting_group: "長岡実行委員会",
      hosting_email: @owner.email, qr_use: true, select1: "参加形式", select_content1: "現地,オンライン",
      select_setting1: 2, free1: "自由回答", free_setting1: 2
    }
  end
end
