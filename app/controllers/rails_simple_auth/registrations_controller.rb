# frozen_string_literal: true

module RailsSimpleAuth
  class RegistrationsController < BaseController
    skip_before_action :require_authentication, only: %i[new create], raise: false

    unless Rails.env.local?
      rate_limit to: 5, within: 1.hour, by: -> { client_ip }, only: :create,
                 with: -> { redirect_to sign_up_path, alert: 'Too many sign up attempts. Please try again later.' }
    end

    def new
      redirect_to resolve_path(:after_sign_in_path) if user_signed_in?
      @user = user_class.new
    end

    def create
      @user = user_class.new(registration_params)

      if @user.save
        after_successful_registration
      else
        render :new, status: :unprocessable_content
      end
    end

    private

    def registration_params
      params.expect(user: %i[email password])
    end

    def after_successful_registration
      destroy_temporary_user_session(@user)

      if RailsSimpleAuth.configuration.email_confirmation_enabled
        send_confirmation_email(@user)
        run_after_sign_up_callback(@user)
        redirect_to new_session_path, notice: 'Account created! Please check your email to confirm your account.'
      else
        create_session_for(@user)
        run_after_sign_up_callback(@user)
        redirect_to stored_location_or_default(:after_sign_up_path), notice: 'Account created successfully!'
      end
    end

    def send_confirmation_email(user)
      return unless user.respond_to?(:generate_confirmation_token)

      token = user.generate_confirmation_token
      RailsSimpleAuth.configuration.mailer.confirmation(user, token).deliver_later
    end
  end
end
