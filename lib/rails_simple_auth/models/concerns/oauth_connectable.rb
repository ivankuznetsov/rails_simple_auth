# frozen_string_literal: true

module RailsSimpleAuth
  module Models
    module Concerns
      module OAuthConnectable
        extend ActiveSupport::Concern

        # This concern provides helpers for OAuth integration.
        # The host app is responsible for storing OAuth data if needed
        # (provider, uid, tokens, etc.)

        class_methods do
          # Find or create user from OAuth data
          # Override this in your User model for custom behavior
          #
          # Behavior for existing accounts controlled by oauth_link_existing_accounts config:
          # - true (default): Links OAuth to existing email accounts (safe for providers that verify emails)
          # - false: Only allows OAuth for accounts created via OAuth with same provider+uid
          def from_oauth(auth_hash)
            email = auth_hash.dig('info', 'email')
            provider = auth_hash['provider']
            uid = auth_hash['uid']

            if email.blank?
              Rails.logger.warn(
                '[RailsSimpleAuth] OAuth auth_hash missing email. ' \
                "Provider: #{provider}, UID: #{uid}. Ensure email scope is requested."
              )
              return nil
            end

            # First, try to find by OAuth credentials (provider + uid)
            # This is the safe path for returning existing users
            user = find_by_oauth(provider, uid) if respond_to?(:find_by_oauth)

            # If found by OAuth credentials, return the user
            return user if user

            # Check if email already exists (created via password or different OAuth)
            existing_user = find_by_email(email)
            if existing_user
              # Configurable: allow linking OAuth to existing accounts
              # Only enable for providers trusted to supply verified email addresses.
              if RailsSimpleAuth.configuration.oauth_link_existing_accounts
                matched_email = existing_user.email
                return existing_user.with_lock do
                  # Reload under the lock before checking confirmation state.
                  next nil if existing_user.email != matched_email

                  # Confirm the current email only; OAuth does not verify a pending replacement.
                  pending_email = existing_user.respond_to?(:unconfirmed_email) &&
                                  existing_user.unconfirmed_email.present?
                  if existing_user.respond_to?(:confirmed_at=) && existing_user.confirmed_at.nil? && !pending_email
                    existing_user.confirmed_at = Time.current
                  end

                  # Call hook to store OAuth credentials on existing user
                  if existing_user.respond_to?(:assign_oauth_attributes)
                    existing_user.assign_oauth_attributes(auth_hash)
                  end
                  if existing_user.changed? && !existing_user.save
                    Rails.logger.error(
                      "[RailsSimpleAuth] OAuth account linking failed for email: #{email}, " \
                      "provider: #{provider}, errors: #{existing_user.errors.full_messages.join(', ')}"
                    )
                    next nil
                  end

                  Rails.logger.info(
                    "[RailsSimpleAuth] OAuth linked to existing account: #{email}. " \
                    "Provider: #{provider}."
                  )
                  existing_user
                end
              else
                Rails.logger.warn(
                  "[RailsSimpleAuth] OAuth login rejected for existing email: #{email}. " \
                  "Provider: #{provider}. Set oauth_link_existing_accounts=true to allow."
                )
                return nil
              end
            end

            # Create new user for new OAuth signups
            user = new(
              email: email,
              password: SecureRandom.hex(32) # Random password for OAuth users
            )

            # Auto-confirm OAuth users (email verified by provider)
            user.confirmed_at = Time.current if user.respond_to?(:confirmed_at=)

            # Call hook for custom OAuth field mapping (should set provider/uid)
            user.assign_oauth_attributes(auth_hash) if user.respond_to?(:assign_oauth_attributes)

            unless user.save
              Rails.logger.error(
                "[RailsSimpleAuth] OAuth user creation failed for email: #{email}, " \
                "provider: #{provider}, errors: #{user.errors.full_messages.join(', ')}"
              )
              return nil
            end

            user
          end
        end

        # Override this in your model to map additional OAuth fields
        # Example:
        #   def assign_oauth_attributes(auth_hash)
        #     self.name = auth_hash.dig("info", "name")
        #     self.avatar_url = auth_hash.dig("info", "image")
        #     self.oauth_provider = auth_hash["provider"]
        #     self.oauth_uid = auth_hash["uid"]
        #   end
        def assign_oauth_attributes(auth_hash)
          # Default: no-op, override in your model
        end
      end
    end
  end
end
