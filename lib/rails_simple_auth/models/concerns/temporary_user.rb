# frozen_string_literal: true

module RailsSimpleAuth
  module Models
    module Concerns
      module TemporaryUser
        extend ActiveSupport::Concern

        included do
          scope :temporary, -> { where(temporary: true) }
          scope :permanent, -> { where(temporary: false) }
          scope :temporary_expired, lambda { |days = nil|
            cleanup_days = days || RailsSimpleAuth.configuration.temporary_user_cleanup_days
            raise ConfigurationError, 'temporary_user_cleanup_days must be configured' unless cleanup_days&.positive?

            temporary.where(created_at: ...cleanup_days.days.ago)
          }
        end

        def temporary?
          temporary == true
        end

        def permanent?
          !temporary?
        end

        # Convert a temporary user to a permanent user with email and password
        # Returns self on success, false on failure (with errors populated)
        def convert_to_permanent!(email:, password:)
          # Validate email uniqueness upfront (better UX than failing inside transaction)
          if self.class.where.not(id: id).exists?(email: email)
            errors.add(:email, 'has already been taken')
            return false
          end

          transaction do
            # Reload to discard any unpersisted changes from callbacks before locking
            reload
            lock!

            unless temporary?
              errors.add(:base, 'User is already permanent')
              raise ActiveRecord::Rollback
            end

            attrs = {
              email: email,
              password: password,
              temporary: false
            }
            # Reset confirmation so new email requires verification
            attrs[:confirmed_at] = nil if respond_to?(:confirmed_at)

            raise ActiveRecord::Rollback unless update(attrs)
          end

          # Check if transaction was rolled back
          return false if errors.any? || temporary?

          Rails.logger.info("[RailsSimpleAuth] Converted temporary user #{id} to permanent")
          send_conversion_confirmation_email
          self
        rescue ActiveRecord::RecordNotUnique
          errors.add(:email, 'has already been taken')
          false
        end

        private

        def send_conversion_confirmation_email
          return unless RailsSimpleAuth.configuration.email_confirmation_enabled
          return unless respond_to?(:generate_confirmation_token)

          token = generate_confirmation_token
          RailsSimpleAuth.configuration.mailer.confirmation(self, token).deliver_later

          Rails.logger.info("[RailsSimpleAuth] Queued confirmation email for converted user #{id}")
        rescue StandardError => e
          Rails.logger.error("[RailsSimpleAuth] Failed to send confirmation email for user #{id}: #{e.message}")
        end
      end
    end
  end
end
