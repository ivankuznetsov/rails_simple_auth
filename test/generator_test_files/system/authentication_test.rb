# frozen_string_literal: true

require 'test_helper'

class AuthenticationTest < ActionDispatch::IntegrationTest
  def setup
    super
    @landing_page = Pages::LandingPage.new(self)
    @sign_in_page = Pages::SignInPage.new(self)
    @sign_up_page = Pages::SignUpPage.new(self)
    @dashboard_page = Pages::DashboardPage.new(self)
  end

  test 'landing page displays correctly' do
    @landing_page.visit_page

    assert_predicate @landing_page, :displayed?, 'Landing page should be displayed'
  end

  test 'unauthenticated user can navigate from landing to sign in' do
    @landing_page.visit_page
    sign_in_page = @landing_page.click_sign_in

    assert_predicate sign_in_page, :displayed?, 'Sign in page should be displayed'
  end

  test 'unauthenticated user can navigate from landing to sign up' do
    @landing_page.visit_page
    sign_up_page = @landing_page.click_sign_up

    assert_predicate sign_up_page, :displayed?, 'Sign up page should be displayed'
  end

  test 'unauthenticated user accessing dashboard is redirected to sign in' do
    @dashboard_page.visit_page

    assert_predicate @sign_in_page, :displayed?, 'User should be redirected to sign in page'
  end

  test 'user can sign up with valid credentials' do
    email = "test_#{SecureRandom.hex(4)}@example.com"
    password = 'password123'

    @sign_up_page.visit_page
    @sign_up_page.sign_up(email: email, password: password)

    # After sign up, user should see confirmation message
    assert has_text?('Account created') || has_text?('check your email'),
           'User should see confirmation instructions after sign up'
  end

  test 'user cannot sign up with existing email' do
    email = "existing_#{SecureRandom.hex(4)}@example.com"
    password = 'password123'

    # Create user first
    User.create!(email: email, password: password, password_confirmation: password, confirmed_at: Time.current)

    @sign_up_page.visit_page
    @sign_up_page.sign_up(email: email, password: password)

    assert_predicate @sign_up_page, :has_email_taken_error?, 'Should show email taken error'
  end

  test 'user cannot sign up with short password' do
    email = "short_pwd_#{SecureRandom.hex(4)}@example.com"

    @sign_up_page.visit_page
    @sign_up_page.sign_up(email: email, password: 'short')

    assert_predicate @sign_up_page, :has_password_too_short_error?, 'Should show password too short error'
  end

  test 'confirmed user can sign in with valid credentials' do
    email = "signin_#{SecureRandom.hex(4)}@example.com"
    password = 'password123'

    User.create!(email: email, password: password, password_confirmation: password, confirmed_at: Time.current)

    @sign_in_page.visit_page
    @sign_in_page.sign_in(email: email, password: password)

    assert_predicate @dashboard_page, :displayed?, 'User should be redirected to dashboard after sign in'
    assert @dashboard_page.has_welcome_message_for?(email), 'Dashboard should show user email'
  end

  test 'user cannot sign in with invalid password' do
    email = "invalid_pwd_#{SecureRandom.hex(4)}@example.com"
    password = 'password123'

    User.create!(email: email, password: password, password_confirmation: password, confirmed_at: Time.current)

    @sign_in_page.visit_page
    @sign_in_page.sign_in(email: email, password: 'wrongpassword')

    assert_predicate @sign_in_page, :has_invalid_credentials_error?, 'Should show invalid credentials error'
  end

  test 'user cannot sign in with non-existent email' do
    @sign_in_page.visit_page
    @sign_in_page.sign_in(email: 'nonexistent@example.com', password: 'password123')

    assert_predicate @sign_in_page, :has_invalid_credentials_error?, 'Should show invalid credentials error'
  end

  test 'authenticated user can sign out' do
    email = "signout_#{SecureRandom.hex(4)}@example.com"
    password = 'password123'

    User.create!(email: email, password: password, password_confirmation: password, confirmed_at: Time.current)

    @sign_in_page.visit_page
    @sign_in_page.sign_in(email: email, password: password)

    assert_predicate @dashboard_page, :displayed?, 'User should be on dashboard'

    @dashboard_page.sign_out

    # After sign out, user should be on sign in page or landing
    assert @sign_in_page.displayed? || @landing_page.displayed?,
           'User should be redirected after sign out'
  end

  test 'authenticated user visiting landing page is redirected to dashboard' do
    email = "redirect_#{SecureRandom.hex(4)}@example.com"
    password = 'password123'

    User.create!(email: email, password: password, password_confirmation: password, confirmed_at: Time.current)

    @sign_in_page.visit_page
    @sign_in_page.sign_in(email: email, password: password)

    assert_predicate @dashboard_page, :displayed?, 'User should be on dashboard'

    @landing_page.visit_page

    assert_predicate @dashboard_page, :displayed?, 'Authenticated user should be redirected to dashboard from landing'
  end
end
