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

        def permanent_user_signed_in?
          user_signed_in? && (!current_user.respond_to?(:permanent?) || current_user.permanent?)
        end

        def store_location_for_redirect
          return unless request.get?

          path = request.fullpath

          # SECURITY: Validate path to prevent open redirect attacks
          # Only store relative paths that start with / but not //
          return unless path.start_with?('/')
          return if path.start_with?('//')

          session[:return_to] = path
        end

        def store_referrer_for_redirect
          # Don't overwrite existing stored location (e.g., from require_authentication)
          return if session[:return_to].present?

          referrer = request.referer
          return if referrer.blank?

          # SECURITY: Only store referrer if it's from the same origin
          begin
            referrer_uri = URI.parse(referrer)
            request_uri = URI.parse(request.url)

            return unless referrer_uri.host == request_uri.host

            path = referrer_uri.path
            path += "?#{referrer_uri.query}" if referrer_uri.query.present?

            # SECURITY: Validate path to prevent open redirect attacks
            return unless path.start_with?('/')
            return if path.start_with?('//')

            session[:return_to] = path
          rescue URI::InvalidURIError
            # Invalid referrer, ignore
          end
        end

        # Returns the stored post-auth return path (consuming it from the session) or,
        # if none was stored or the stored value fails defense-in-depth validation,
        # the resolved fallback path for the given config key (e.g., :after_sign_in_path,
        # :after_sign_up_path).
        #
        # SECURITY: store_location_for_redirect validates paths at write time, but
        # nothing prevents host-app code from writing to session[:return_to] directly.
        # We re-check here so a poisoned value (open-redirect, javascript:, malformed
        # string) falls back instead of raising UnsafeRedirectError or worse.
        #
        # NOTE: mutates the session — calling twice returns the fallback the second time.
        def stored_location_or_default(fallback_path_config = :after_sign_in_path)
          stored = session.delete(:return_to)
          return resolve_path(fallback_path_config) unless safe_stored_location?(stored)

          stored
        end

        def safe_stored_location?(path)
          path.is_a?(String) && path.start_with?('/') && !path.start_with?('//')
        end

        def redirect_to_sign_in
          respond_to do |format|
            format.html { redirect_to new_session_path, alert: 'Please sign in to continue.' }
            format.json { render json: { error: 'Authentication required' }, status: :unauthorized }
            format.turbo_stream { redirect_to new_session_path, alert: 'Please sign in to continue.' }
          end
        end

        def client_ip
          request.headers['CF-Connecting-IP'] ||
            request.headers['X-Forwarded-For']&.split(',')&.first&.strip ||
            request.remote_ip
        end

        def resolve_path(config_key)
          path_config = RailsSimpleAuth.configuration.public_send(config_key)

          case path_config
          when Symbol then send(path_config)
          when Proc then path_config.call(self)
          when String then path_config
          else
            Rails.logger.warn(
              "[RailsSimpleAuth] Invalid path configuration for #{config_key}: " \
              "expected Symbol, Proc, or String, got #{path_config.class.name}. " \
              'Falling back to root_path.'
            )
            root_path
          end
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
