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

        def convert_to_permanent!(email:, password:)
          transaction do
            lock!
            raise RailsSimpleAuth::Error, "User #{id} is already permanent" unless temporary?

            attrs = {
              email_address: email,
              password: password,
              temporary: false
            }
            # Reset confirmation so new email requires verification
            attrs[:confirmed_at] = nil if respond_to?(:confirmed_at)

            update!(attrs)
          end

          Rails.logger.info("[RailsSimpleAuth] Converted temporary user #{id} to permanent")
          send_conversion_confirmation_email
          self
        rescue ActiveRecord::RecordNotUnique
          errors.add(:email_address, 'has already been taken')
          raise ActiveRecord::RecordInvalid, self
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
