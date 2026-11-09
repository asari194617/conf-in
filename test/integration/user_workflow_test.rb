require "test_helper"

class UserWorkflowTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  test "register, edit a profile, sign out and sign back in" do
    get new_user_registration_path
    assert_response :success
    assert_select 'form input[name="user[name]"]'

    assert_difference "User.count", 1 do
      post user_registration_path, params: {
        user: { name: "参加者", email: "participant@example.test", password: "test-password",
                password_confirmation: "test-password", domicile: "長岡市", tw_id: "participant" }
      }
    end
    assert_response :redirect

    user = User.find_by!(email: "participant@example.test")
    assert_equal "長岡市", user.domicile
    assert_equal "participant", user.tw_id
    assert_not_empty user.qr_secret

    get edit_user_registration_path
    assert_response :success
    assert_select 'form input[name="user[current_password]"]'

    put user_registration_path, params: {
      user: { name: "新しい参加者名", office: "長岡高専", current_password: "test-password" }
    }
    assert_response :redirect

    get user_path(user)
    assert_response :success
    assert_select "h1, h2", text: /新しい参加者名/
    assert_includes response.body, "長岡高専"

    delete destroy_user_session_path
    assert_response :redirect
    get edit_user_registration_path
    assert_redirected_to new_user_session_path

    get new_user_session_path
    assert_response :success
    post user_session_path, params: { user: { email: user.email, password: "test-password" } }
    assert_response :redirect
    get edit_user_registration_path
    assert_response :success

    assert_difference "User.count", -1 do
      delete user_registration_path
    end
    assert_response :redirect
  end

  test "reset a password using the link delivered by email" do
    user = User.create!(name: "再設定", email: "reset@example.test", password: "original-password")

    get new_user_password_path
    assert_response :success

    messages = capture_emails do
      post user_password_path, params: { user: { email: user.email } }
      assert_response :redirect
    end
    assert_equal 1, messages.size
    assert_equal [user.email], messages.first.to
    token = messages.first.body.decoded[/reset_password_token=([\w-]+)/, 1]
    assert token, "the reset email should contain a password reset link"

    get edit_user_password_path(reset_password_token: token)
    assert_response :success
    assert_select 'form input[name="user[reset_password_token]"][value=?]', token

    put user_password_path, params: {
      user: { reset_password_token: token, password: "new-password", password_confirmation: "new-password" }
    }
    assert_response :redirect
    assert user.reload.valid_password?("new-password")
  end

  test "email a QR ticket only while signed in and with a valid destination" do
    user = User.create!(name: "QR参加者", email: "qr@example.test", password: "test-password")

    assert_no_emails do
      post send_qr_users_path, params: { email: user.email }
      assert_redirected_to new_user_session_path
    end
    post user_session_path, params: { user: { email: user.email, password: "test-password" } }
    assert_response :redirect

    assert_no_emails do
      post send_qr_users_path, params: { email: "bad-address" }
      assert_response :redirect
    end
    messages = capture_emails do
      post send_qr_users_path, params: { email: "ticket@example.test" }
      assert_response :redirect
    end
    assert_equal 1, messages.size
    assert_equal ["ticket@example.test"], messages.first.to
    assert_equal "image/png", messages.first.attachments.first.mime_type
    assert messages.first.attachments.first.decoded.start_with?("\x89PNG\r\n\x1a\n".b)

    get icon_user_path(user, size: :bigger)
    assert_redirected_to "/images/73.png"
    follow_redirect!
    assert_response :success
    assert_equal "image/png", response.media_type
  end
end
