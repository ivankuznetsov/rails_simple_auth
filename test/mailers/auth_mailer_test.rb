# frozen_string_literal: true

require 'test_helper'

# Set up mailer test mode
ActionMailer::Base.delivery_method = :test
ActionMailer::Base.perform_deliveries = true

# Configure routes for mailer URLs
Rails.application.routes.draw do
  get '/confirm/:token', to: 'confirmations#show', as: :confirmation
  get '/magic_link/:token', to: 'sessions#magic_link', as: :magic_link
  get '/password/edit/:token', to: 'passwords#edit', as: :edit_password
end

class AuthMailerTest < Minitest::Test
  def setup
    super
    ActionMailer::Base.deliveries.clear
    RailsSimpleAuth.configuration.mailer_sender = 'noreply@example.com'
    Rails.application.routes.default_url_options[:host] = 'example.com'
  end

  def test_confirmation_email
    user = User.create!(email: 'test@example.com', password: 'password123')
    token = user.generate_confirmation_token

    mail = RailsSimpleAuth::AuthMailer.confirmation(user, token)

    assert_equal ['test@example.com'], mail.to
    assert_equal ['noreply@example.com'], mail.from
    assert_equal 'Confirm your email', mail.subject
  end

  def test_confirmation_email_uses_confirmable_email_for_reconfirmation
    user = User.create!(email: 'test@example.com', password: 'password123', confirmed_at: Time.current)
    user.update_column(:unconfirmed_email, 'new@example.com') # rubocop:disable Rails/SkipsModelValidations
    token = user.generate_confirmation_token

    mail = RailsSimpleAuth::AuthMailer.confirmation(user, token)

    # Should send to the unconfirmed (new) email, not the current email
    assert_equal ['new@example.com'], mail.to
  end

  def test_magic_link_email
    user = User.create!(email: 'test@example.com', password: 'password123')
    token = user.generate_magic_link_token

    mail = RailsSimpleAuth::AuthMailer.magic_link(user, token)

    assert_equal ['test@example.com'], mail.to
    assert_equal ['noreply@example.com'], mail.from
    assert_equal 'Sign in to your account', mail.subject
  end

  def test_password_reset_email
    user = User.create!(email: 'test@example.com', password: 'password123')
    token = user.generate_password_reset_token

    mail = RailsSimpleAuth::AuthMailer.password_reset(user, token)

    assert_equal ['test@example.com'], mail.to
    assert_equal ['noreply@example.com'], mail.from
    assert_equal 'Reset your password', mail.subject
  end

  def test_mailer_sender_is_configurable
    RailsSimpleAuth.configuration.mailer_sender = 'auth@myapp.com'
    user = User.create!(email: 'test@example.com', password: 'password123')
    token = user.generate_confirmation_token

    mail = RailsSimpleAuth::AuthMailer.confirmation(user, token)

    assert_equal ['auth@myapp.com'], mail.from
  end
end
