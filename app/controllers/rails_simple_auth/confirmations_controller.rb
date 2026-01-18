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
      user = user_class.find_signed(params[:token], purpose: :email_confirmation)

      if user
        user.confirm! if user.respond_to?(:confirm!)
        run_after_confirmation_callback(user)
        redirect_to resolve_path(:after_confirmation_path), notice: 'Email confirmed! You can now sign in.'
      else
        redirect_to new_confirmation_path, alert: 'Invalid or expired confirmation link.'
      end
    end

    def new; end

    def create
      user = user_class.find_by(email: params[:email])

      if user.respond_to?(:unconfirmed?) && user.unconfirmed?
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
