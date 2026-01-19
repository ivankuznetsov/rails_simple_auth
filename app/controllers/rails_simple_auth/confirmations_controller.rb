# frozen_string_literal: true

module RailsSimpleAuth
  class ConfirmationsController < BaseController
    skip_before_action :require_authentication, only: %i[new create show], raise: false

    unless Rails.env.local?
      rate_limit to: 3, within: 1.hour, by: -> { client_ip }, only: :create,
                 with: lambda {
                   redirect_to new_confirmation_path, alert: 'Too many confirmation requests. Please try again later.'
                 }
    end

    def show
      user = user_class.find_signed(params[:token], purpose: :confirm_email)

      if user
        confirmed = user.respond_to?(:confirm!) ? user.confirm! : true

        if confirmed
          run_after_confirmation_callback(user)
          redirect_to resolve_path(:after_confirmation_path), notice: 'Email confirmed! You can now sign in.'
        else
          error_message = user.errors.full_messages.first || 'Could not confirm email.'
          redirect_to new_confirmation_path, alert: error_message
        end
      else
        redirect_to new_confirmation_path, alert: 'Invalid or expired confirmation link.'
      end
    end

    def new; end

    def create
      user = user_class.find_by(email: params[:email])

      if user.respond_to?(:unconfirmed_or_reconfirming?) && user.unconfirmed_or_reconfirming?
        token = user.generate_confirmation_token
        RailsSimpleAuth.configuration.mailer.confirmation(user, token).deliver_later
      end

      redirect_to new_session_path,
                  notice: 'If an unconfirmed account exists with that email, confirmation instructions have been sent.'
    end

    private

    def run_after_confirmation_callback(user)
      callback = RailsSimpleAuth.configuration.after_confirmation_callback
      callback&.call(user, self)
    end
  end
end
