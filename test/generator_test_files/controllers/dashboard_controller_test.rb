# frozen_string_literal: true

require 'test_helper'

class DashboardControllerTest < ActionDispatch::IntegrationTest
  test 'should redirect unauthenticated user to sign in' do
    get dashboard_path

    assert_redirected_to new_session_path
  end

  test 'should get show for authenticated user' do
    user = User.create!(
      email: 'dashboard@example.com',
      password: 'password123',
      password_confirmation: 'password123',
      confirmed_at: Time.current
    )

    # Sign in the user
    post session_path, params: { email: user.email, password: 'password123' }

    get dashboard_path

    assert_response :success
    assert_match 'Dashboard', response.body
    assert_match user.email, response.body
  end

  test 'should sign out user' do
    user = User.create!(
      email: 'signout@example.com',
      password: 'password123',
      password_confirmation: 'password123',
      confirmed_at: Time.current
    )

    # Sign in the user
    post session_path, params: { email: user.email, password: 'password123' }

    # Sign out
    delete session_path

    # Should be redirected
    assert_response :redirect

    # Dashboard should now redirect to sign in
    get dashboard_path

    assert_redirected_to new_session_path
  end
end
