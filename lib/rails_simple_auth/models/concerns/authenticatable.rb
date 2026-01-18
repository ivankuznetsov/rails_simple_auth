# frozen_string_literal: true

module RailsSimpleAuth
  module Models
    module Concerns
      module Authenticatable
        extend ActiveSupport::Concern

        included do
          has_secure_password

          has_many :sessions,
                   class_name: 'RailsSimpleAuth::Session',
                   dependent: :destroy,
                   inverse_of: :user

          validates :email,
                    presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP },
                    unless: :temporary?

          validate :password_meets_minimum_length, if: :password_required?

          normalizes :email, with: ->(email) { email.strip.downcase }
        end

        class_methods do
          def find_by_email(email)
            return nil if email.blank?

            find_by(email: email.to_s.strip.downcase)
          end
        end

        def generate_password_reset_token
          signed_id(purpose: :password_reset, expires_in: RailsSimpleAuth.configuration.password_reset_expiry)
        end

        def generate_magic_link_token
          signed_id(purpose: :magic_link, expires_in: RailsSimpleAuth.configuration.magic_link_expiry)
        end

        def invalidate_all_sessions!
          count = sessions.count
          sessions.destroy_all
          Rails.logger.info("[RailsSimpleAuth] Invalidated #{count} sessions for user #{id}")
          count
        end

        # Returns false by default. Override in TemporaryUser concern.
        def temporary?
          false
        end

        private

        def password_required?
          return false if temporary?

          password_digest.blank? || password.present?
        end

        def password_meets_minimum_length
          minimum = RailsSimpleAuth.configuration.password_minimum_length
          return if password.blank? || password.length >= minimum

          errors.add(:password, "must be at least #{minimum} characters")
        end
      end
    end
  end
end
