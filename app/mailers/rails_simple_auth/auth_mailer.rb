# frozen_string_literal: true

module RailsSimpleAuth
  class AuthMailer < ApplicationMailer
    default from: -> { RailsSimpleAuth.configuration.mailer_sender }

    def confirmation(user, token)
      @user = user
      @token = token
      @confirmation_url = main_app.confirmation_url(token: token)

      mail(
        to: user.email_address,
        subject: 'Confirm your email'
      )
    end

    def magic_link(user, token)
      @user = user
      @token = token
      @magic_link_url = main_app.magic_link_url(token: token)

      mail(
        to: user.email_address,
        subject: 'Sign in to your account'
      )
    end

    def password_reset(user, token)
      @user = user
      @token = token
      @password_reset_url = main_app.edit_password_url(token: token)

      mail(
        to: user.email_address,
        subject: 'Reset your password'
      )
    end

    private

    def main_app
      Rails.application.routes.url_helpers
    end
  end
end
