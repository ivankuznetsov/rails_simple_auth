# frozen_string_literal: true

require 'test_helper'

class PasswordResetTest < ActionDispatch::IntegrationTest
  def setup
    super
    @sign_in_page = Pages::SignInPage.new(self)
    @password_reset_page = Pages::PasswordResetPage.new(self)
    @dashboard_page = Pages::DashboardPage.new(self)
  end

  test 'password reset page displays correctly' do
    @password_reset_page.visit_page

    assert_predicate @password_reset_page, :displayed?, 'Password reset page should be displayed'
  end

  test 'user can navigate to password reset from sign in page' do
    @sign_in_page.visit_page
    password_reset_page = @sign_in_page.click_forgot_password

    assert_predicate password_reset_page, :displayed?, 'Password reset page should be displayed'
  end

  test 'user can request password reset for existing email' do
    email = "reset_#{SecureRandom.hex(4)}@example.com"
    password = 'password123'

    User.create!(email: email, password: password, password_confirmation: password, confirmed_at: Time.current)

    @password_reset_page.visit_page
    @password_reset_page.request_reset(email: email)

    assert_predicate @password_reset_page, :has_reset_email_sent_message?,
                     'Should show reset email sent message'
  end

  test 'user can request password reset for non-existent email without revealing info' do
    @password_reset_page.visit_page
    @password_reset_page.request_reset(email: 'nonexistent@example.com')

    # Should show same message to prevent email enumeration
    assert_predicate @password_reset_page, :has_reset_email_sent_message?,
                     'Should show reset email sent message even for non-existent email'
  end

  test 'user can reset password with valid token' do
    email = "reset_valid_#{SecureRandom.hex(4)}@example.com"
    password = 'password123'
    new_password = 'newpassword456'

    user = User.create!(email: email, password: password, password_confirmation: password, confirmed_at: Time.current)

    # Generate a valid password reset token
    token = user.generate_password_reset_token

    password_edit_page = Pages::PasswordEditPage.new(self)
    password_edit_page.visit_page(token: token)
    password_edit_page.reset_password(password: new_password)

    # After successful reset, user should see success message
    assert has_text?('Password has been reset') || has_text?('new password'),
           'User should see password reset success message'

    # Reload user to verify password changed
    user.reload

    # Verify new password works by authenticating directly (not through browser)
    assert user.authenticate(new_password), 'New password should authenticate the user'
  end

  test 'user cannot reset password with invalid token' do
    password_edit_page = Pages::PasswordEditPage.new(self)
    password_edit_page.visit_page(token: 'invalid_token_123')

    # Should show error or be on error page
    assert password_edit_page.has_invalid_token_error? || has_text?('invalid') || has_text?('expired'),
           'Should show invalid or expired token error'
  end
end
