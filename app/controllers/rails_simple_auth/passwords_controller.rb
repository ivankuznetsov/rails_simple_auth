# frozen_string_literal: true

module RailsSimpleAuth
  class PasswordsController < BaseController
    skip_before_action :require_authentication, only: %i[new create edit update], raise: false
    before_action :set_user_from_token, only: %i[edit update]

    unless Rails.env.local?
      rate_limit to: 3, within: 1.hour, by: -> { client_ip }, only: :create,
                 with: lambda {
                   redirect_to new_password_path, alert: 'Too many password reset requests. Please try again later.'
                 }
    end

    def new; end

    def edit; end

    def create
      user = user_class.find_by(email: params[:email_address])

      if user && can_reset_password?(user)
        token = user.generate_password_reset_token
        RailsSimpleAuth.configuration.mailer.password_reset(user, token).deliver_later
      end

      redirect_to new_session_path,
                  notice: 'If an account exists with that email, password reset instructions have been sent.'
    end

    def update
      ActiveRecord::Base.transaction do
        if @user.update(password_params)
          @user.invalidate_all_sessions!
          redirect_to new_session_path, notice: 'Password has been reset. Please sign in with your new password.'
        else
          render :edit, status: :unprocessable_content
          raise ActiveRecord::Rollback
        end
      end
    rescue ActiveRecord::StatementInvalid => e
      Rails.logger.error(
        "[RailsSimpleAuth] Session invalidation failed after password reset for user #{@user.id}: #{e.message}"
      )
      # Password was rolled back due to transaction, redirect with error
      redirect_to new_password_path, alert: 'Password reset failed. Please try again.'
    end

    private

    def set_user_from_token
      @user = user_class.find_signed(params[:token], purpose: :password_reset)
      redirect_to new_password_path, alert: 'Invalid or expired password reset link.' unless @user
    end

    def can_reset_password?(user)
      return true unless RailsSimpleAuth.configuration.email_confirmation_enabled
      return true unless user.respond_to?(:confirmed?)

      user.confirmed?
    end

    def password_params
      params.expect(user: %i[password password_confirmation])
    end
  end
end
