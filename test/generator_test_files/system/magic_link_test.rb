# frozen_string_literal: true

require 'test_helper'

class MagicLinkTest < ActionDispatch::IntegrationTest
  def setup
    super
    @sign_in_page = Pages::SignInPage.new(self)
    @magic_link_page = Pages::MagicLinkPage.new(self)
    @dashboard_page = Pages::DashboardPage.new(self)
  end

  test 'magic link page displays correctly' do
    @magic_link_page.visit_page

    assert_predicate @magic_link_page, :displayed?, 'Magic link page should be displayed'
  end

  test 'user can navigate to magic link from sign in page' do
    @sign_in_page.visit_page
    magic_link_page = @sign_in_page.click_magic_link

    assert_predicate magic_link_page, :displayed?, 'Magic link page should be displayed'
  end

  test 'user can request magic link for existing email' do
    email = "magic_#{SecureRandom.hex(4)}@example.com"
    password = 'password123'

    User.create!(email: email, password: password, password_confirmation: password, confirmed_at: Time.current)

    @magic_link_page.visit_page
    @magic_link_page.request_magic_link(email: email)

    assert_predicate @magic_link_page, :has_magic_link_sent_message?,
                     'Should show magic link sent message'
  end

  test 'user can sign in with valid magic link token' do
    email = "magic_valid_#{SecureRandom.hex(4)}@example.com"
    password = 'password123'

    user = User.create!(email: email, password: password, password_confirmation: password, confirmed_at: Time.current)

    # Generate a valid magic link token
    token = user.generate_magic_link_token

    visit "/magic_link?token=#{token}"

    assert_predicate @dashboard_page, :displayed?, 'User should be signed in and on dashboard after using magic link'
    assert @dashboard_page.has_welcome_message_for?(email), 'Dashboard should show user email'
  end

  test 'user cannot sign in with invalid magic link token' do
    visit '/magic_link?token=invalid_token_123'

    # Should show error or be redirected to sign in
    assert @sign_in_page.displayed? || has_text?('invalid') || has_text?('expired'),
           'Should show error or redirect to sign in for invalid token'
  end

  test 'requesting magic link for non-existent email does not reveal information' do
    @magic_link_page.visit_page
    @magic_link_page.request_magic_link(email: 'nonexistent@example.com')

    # Should show same message to prevent email enumeration
    assert_predicate @magic_link_page, :has_magic_link_sent_message?,
                     'Should show magic link sent message even for non-existent email'
  end
end
