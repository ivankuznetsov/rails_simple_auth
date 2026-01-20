# frozen_string_literal: true

module RailsSimpleAuth
  class OmniauthCallbacksController < BaseController
    skip_before_action :require_authentication, raise: false
    skip_before_action :verify_authenticity_token, only: :create

    def create
      auth_hash = request.env['omniauth.auth']
      provider = params[:provider]

      unless RailsSimpleAuth.configuration.oauth_provider_enabled?(provider)
        redirect_to new_session_path, alert: 'OAuth provider not enabled.'
        return
      end

      user = user_class.from_oauth(auth_hash)

      display_name = RailsSimpleAuth.configuration.oauth_provider_display_name(provider)

      if user&.persisted?
        destroy_temporary_user_session(user)
        create_session_for(user)
        run_after_sign_in_callback(user)
        redirect_to resolve_path(:after_sign_in_path),
                    notice: "Signed in successfully with #{display_name}."
      else
        redirect_to new_session_path, alert: "Could not authenticate with #{display_name}."
      end
    end

    def failure
      error = request.env['omniauth.error']
      error_type = request.env['omniauth.error.type']
      strategy = request.env['omniauth.error.strategy']&.name

      Rails.logger.error(
        '[RailsSimpleAuth] OAuth failure: ' \
        "type=#{error_type.inspect}, " \
        "strategy=#{strategy.inspect}, " \
        "error=#{error&.message.inspect}"
      )

      redirect_to new_session_path, alert: 'Authentication failed. Please try again.'
    end
  end
end
