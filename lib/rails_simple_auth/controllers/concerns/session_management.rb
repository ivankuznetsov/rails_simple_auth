# frozen_string_literal: true

module RailsSimpleAuth
  module Controllers
    module Concerns
      module SessionManagement
        extend ActiveSupport::Concern

        private

        # Standard sign-in sequence: clean up the temporary user, create the real
        # session, fire after_sign_in callbacks, then redirect.
        #
        # NOTE: order matters — destroy_temporary_user_session must run before
        # create_session_for, otherwise the new session cookie is wiped when the
        # temp user is destroyed.
        def sign_in_user_and_redirect(user, notice: 'Signed in successfully.')
          destroy_temporary_user_session(user)
          create_session_for(user)
          run_after_sign_in_callback(user)
          redirect_to stored_location_or_default, notice: notice
        end

        # Create a new session for the user and set the cookie
        def create_session_for(user)
          session_record = user.sessions.create!(
            ip_address: client_ip,
            user_agent: request.user_agent
          )

          cookies.signed.permanent[:session_token] = {
            value: session_record.id,
            httponly: true,
            secure: Rails.env.production?,
            same_site: :lax
          }

          RailsSimpleAuth::Current.user = user
          RailsSimpleAuth::Current.session = session_record

          session_record
        end

        # Destroy the current session
        def destroy_current_session
          if (session_token = cookies.signed.permanent[:session_token])
            RailsSimpleAuth.configuration.session_class.find_by(id: session_token)&.destroy
          end

          cookies.delete(:session_token)
          RailsSimpleAuth::Current.user = nil
          RailsSimpleAuth::Current.session = nil
        end

        # Destroy temporary user session when signing in with a different account
        # This cleans up guest/demo users when they sign in or register
        # @param signing_in_user [User, nil] The user being signed in (to avoid self-destruction)
        def destroy_temporary_user_session(signing_in_user = nil)
          return unless RailsSimpleAuth.configuration.temporary_users_enabled
          return unless RailsSimpleAuth::Current.user&.temporary?

          temp_user = RailsSimpleAuth::Current.user

          # Don't destroy if the user is re-authenticating as themselves
          return if signing_in_user && temp_user.id == signing_in_user.id

          temp_user_id = temp_user.id

          temp_user.transaction do
            destroy_current_session
            temp_user.destroy!
          end

          Rails.logger.info "[RailsSimpleAuth] Destroyed temporary user #{temp_user_id} on sign in"
        rescue ActiveRecord::RecordNotDestroyed => e
          Rails.logger.error("[RailsSimpleAuth] Failed to destroy temporary user #{temp_user_id}: #{e.message}")
        end

        # Run after sign in callback if configured
        def run_after_sign_in_callback(user)
          run_callback(:after_sign_in_callback, user)
        end

        # Run after sign out callback if configured
        def run_after_sign_out_callback(user)
          run_callback(:after_sign_out_callback, user)
        end

        # Run after sign up callback if configured
        def run_after_sign_up_callback(user)
          run_callback(:after_sign_up_callback, user)
        end

        # Run callback with error handling to prevent callback failures
        # from breaking the main auth flow
        def run_callback(callback_name, user)
          callback = RailsSimpleAuth.configuration.public_send(callback_name)
          return unless callback

          callback.call(user, self)
        rescue StandardError => e
          Rails.logger.error(
            "[RailsSimpleAuth] #{callback_name} failed for user #{user&.id}: " \
            "#{e.class.name}: #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}"
          )
          # Don't re-raise - auth action succeeded, callback is secondary
        end
      end
    end
  end
end
