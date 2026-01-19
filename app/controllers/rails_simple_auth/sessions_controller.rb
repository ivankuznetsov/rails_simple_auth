# frozen_string_literal: true

module RailsSimpleAuth
  class SessionsController < BaseController
    skip_before_action :require_authentication,
                       only: %i[new create magic_link_form request_magic_link magic_link_login],
                       raise: false

    unless Rails.env.local?
      rate_limit to: 5, within: 15.minutes, by: -> { client_ip }, only: :create,
                 with: -> { redirect_to new_session_path, alert: 'Too many login attempts. Please try again later.' }

      rate_limit to: 3, within: 10.minutes, by: -> { params[:email].to_s.downcase }, only: :request_magic_link,
                 with: lambda {
                   redirect_to new_session_path, alert: 'Too many magic link requests. Please try again later.'
                 }

      rate_limit to: 5, within: 15.minutes, by: -> { client_ip }, only: :magic_link_login,
                 with: lambda {
                   redirect_to new_session_path, alert: 'Too many magic link attempts. Please try again later.'
                 }
    end

    def new
      return redirect_to resolve_path(:after_sign_in_path) if permanent_user_signed_in?

      store_referrer_for_redirect
    end

    def create
      user = user_class.find_by(email: params[:email]) || user_class.new(password: SecureRandom.hex(32))

      if user.authenticate(params[:password]) && user.persisted?
        if confirmation_required_for?(user)
          @error_message = 'Please confirm your email before signing in.'
          @previous_email = params[:email]
          render :new, status: :unprocessable_content
        else
          sign_in_and_redirect(user)
        end
      else
        Rails.logger.warn("Failed login attempt for email: #{params[:email]} from IP: #{client_ip}")
        @error_message = 'Invalid email or password'
        @previous_email = params[:email]
        render :new, status: :unprocessable_content
      end
    end

    def destroy
      user = current_user
      destroy_current_session
      run_after_sign_out_callback(user) if user
      redirect_to resolve_path(:after_sign_out_path), notice: 'Signed out successfully.'
    end

    def magic_link_form
      return redirect_to resolve_path(:after_sign_in_path) if permanent_user_signed_in?

      store_referrer_for_redirect
    end

    def request_magic_link
      user = user_class.find_by(email: params[:email])

      if user.respond_to?(:generate_magic_link_token)
        token = user.generate_magic_link_token
        RailsSimpleAuth.configuration.mailer.magic_link(user, token).deliver_later
      end

      redirect_to new_session_path, notice: 'If an account exists with that email, a magic link has been sent.'
    end

    def magic_link_login
      user = user_class.find_signed(params[:token], purpose: :magic_link)

      if user
        # Auto-confirm unconfirmed users via magic link (email ownership verified)
        if user.respond_to?(:confirm!) && user.respond_to?(:unconfirmed?) && user.unconfirmed? && !user.confirm!
          # Confirmation failed (e.g., email already taken during reconfirmation)
          error_message = user.errors.full_messages.first || 'Could not confirm email.'
          redirect_to new_session_path, alert: error_message
          return
        end
        sign_in_and_redirect(user)
      else
        redirect_to new_session_path, alert: 'Invalid or expired magic link.'
      end
    end

    private

    def confirmation_required_for?(user)
      RailsSimpleAuth.configuration.email_confirmation_enabled &&
        user.respond_to?(:unconfirmed?) &&
        user.unconfirmed?
    end

    def sign_in_and_redirect(user)
      destroy_temporary_user_session(user)
      create_session_for(user)
      run_after_sign_in_callback(user)
      redirect_to stored_location_or_default, notice: 'Signed in successfully.'
    end
  end
end
