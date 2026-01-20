# frozen_string_literal: true

require 'test_helper'

class HomeControllerTest < ActionDispatch::IntegrationTest
  test 'should get index for unauthenticated user' do
    get root_path

    assert_response :success
    assert_match 'rails_simple_auth Demo', response.body
  end

  test 'should redirect authenticated user to dashboard' do
    user = User.create!(
      email: 'home_redirect@example.com',
      password: 'password123',
      password_confirmation: 'password123',
      confirmed_at: Time.current
    )

    # Sign in the user
    post session_path, params: { email: user.email, password: 'password123' }

    get root_path

    assert_redirected_to dashboard_path
  end
end
