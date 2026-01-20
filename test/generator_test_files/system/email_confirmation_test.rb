# frozen_string_literal: true

require 'test_helper'

class EmailConfirmationTest < ActionDispatch::IntegrationTest
  def setup
    super
    @sign_in_page = Pages::SignInPage.new(self)
    @sign_up_page = Pages::SignUpPage.new(self)
    @confirmation_page = Pages::ConfirmationPage.new(self)
    @dashboard_page = Pages::DashboardPage.new(self)
  end

  test 'unconfirmed user cannot sign in' do
    email = "unconfirmed_#{SecureRandom.hex(4)}@example.com"
    password = 'password123'

    User.create!(email: email, password: password, password_confirmation: password, confirmed_at: nil)

    @sign_in_page.visit_page
    @sign_in_page.sign_in(email: email, password: password)

    # User should either see error or be asked to confirm
    assert @sign_in_page.has_unconfirmed_error? || has_text?('confirm') || @sign_in_page.displayed?,
           'Unconfirmed user should not be able to sign in'
  end

  test 'user can confirm email with valid token' do
    email = "confirm_valid_#{SecureRandom.hex(4)}@example.com"
    password = 'password123'

    user = User.create!(email: email, password: password, password_confirmation: password, confirmed_at: nil)

    # Generate a valid confirmation token
    token = user.generate_confirmation_token

    @confirmation_page.confirm_with_token(token: token)

    # After confirmation, user should see success or be redirected to sign in
    assert @confirmation_page.has_confirmed_message? || @sign_in_page.displayed?,
           'User should see confirmation success or be on sign in page'

    # Verify user can now sign in
    @sign_in_page.visit_page
    @sign_in_page.sign_in(email: email, password: password)

    assert_predicate @dashboard_page, :displayed?, 'Confirmed user should be able to sign in'
  end

  test 'user cannot confirm email with invalid token' do
    visit '/confirmations/invalid_token_123'

    # Should show error
    assert @confirmation_page.has_invalid_token_error? || has_text?('invalid') || has_text?('expired'),
           'Should show invalid or expired token error'
  end

  test 'user can request new confirmation email' do
    email = "resend_#{SecureRandom.hex(4)}@example.com"
    password = 'password123'

    User.create!(email: email, password: password, password_confirmation: password, confirmed_at: nil)

    @confirmation_page.visit_page
    @confirmation_page.request_confirmation(email: email)

    assert_predicate @confirmation_page, :has_confirmation_sent_message?,
                     'Should show confirmation email sent message'
  end
end
