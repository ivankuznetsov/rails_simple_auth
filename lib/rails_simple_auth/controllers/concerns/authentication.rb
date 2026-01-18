# frozen_string_literal: true

module RailsSimpleAuth
  module Controllers
    module Concerns
      module Authentication
        extend ActiveSupport::Concern

        included do
          before_action :set_current_user
          helper_method :current_user, :user_signed_in?
        end

        private

        def set_current_user
          return unless (session_token = cookies.signed.permanent[:session_token])

          session_record = RailsSimpleAuth.configuration.session_class
                             .includes(:user)
                             .active
                             .find_by(id: session_token)

          if session_record
            RailsSimpleAuth::Current.user = session_record.user
            RailsSimpleAuth::Current.session = session_record
          else
            cookies.delete(:session_token)
          end
        end

        def require_authentication
          return if user_signed_in?

          store_location_for_redirect
          redirect_to_sign_in
        end

        def current_user
          RailsSimpleAuth::Current.user
        end

        def user_signed_in?
          current_user.present?
        end

        def store_location_for_redirect
          return unless request.get?

          path = request.fullpath

          # SECURITY: Validate path to prevent open redirect attacks
          # Only store relative paths that start with / but not //
          return unless path.start_with?("/")
          return if path.start_with?("//")

          session[:return_to] = path
        end

        def stored_location_or_default
          session.delete(:return_to) || resolve_path(:after_sign_in_path)
        end

        def redirect_to_sign_in
          respond_to do |format|
            format.html { redirect_to new_session_path, alert: "Please sign in to continue." }
            format.json { render json: { error: "Authentication required" }, status: :unauthorized }
            format.turbo_stream { redirect_to new_session_path, alert: "Please sign in to continue." }
          end
        end

        def client_ip
          request.headers["CF-Connecting-IP"] ||
            request.headers["X-Forwarded-For"]&.split(",")&.first&.strip ||
            request.remote_ip
        end

        def resolve_path(config_key)
          path_config = RailsSimpleAuth.configuration.public_send(config_key)

          result = case path_config
          when Symbol then send(path_config)
          when Proc then path_config.call(self)
          when String then path_config
          else
                     Rails.logger.warn(
                       "[RailsSimpleAuth] Invalid path configuration for #{config_key}: " \
                       "expected Symbol, Proc, or String, got #{path_config.class.name}. " \
                       "Falling back to root_path."
                     )
                     root_path
          end
          result
        rescue NoMethodError => e
          Rails.logger.error(
            "[RailsSimpleAuth] Path helper '#{path_config}' not found for #{config_key}. " \
            "Ensure the route exists. Falling back to root_path. Error: #{e.message}"
          )
          root_path
        end
      end
    end
  end
end
