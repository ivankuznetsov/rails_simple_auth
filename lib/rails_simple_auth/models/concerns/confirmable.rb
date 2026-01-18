# frozen_string_literal: true

module RailsSimpleAuth
  module Models
    module Concerns
      module Confirmable
        extend ActiveSupport::Concern

        included do
          # Requires `confirmed_at` datetime column
          # Optional `unconfirmed_email` string column for reconfirmation
          scope :confirmed, -> { where.not(confirmed_at: nil) }
          scope :unconfirmed, -> { where(confirmed_at: nil) }
        end

        # Check if user has confirmed their email
        def confirmed?
          confirmed_at.present?
        end

        # Check if user has NOT confirmed their email
        def unconfirmed?
          !confirmed?
        end

        # Check if user is changing their email (reconfirmation)
        def reconfirming?
          respond_to?(:unconfirmed_email) && unconfirmed_email.present?
        end

        # Check if user needs confirmation (either unconfirmed or reconfirming)
        def unconfirmed_or_reconfirming?
          unconfirmed? || reconfirming?
        end

        # Get the email that needs confirmation
        def confirmable_email
          reconfirming? ? unconfirmed_email : email
        end

        # Confirm the user's email
        # Handles both initial confirmation and reconfirmation (email change)
        # Also sets temporary: false if TemporaryUser concern is included
        # Returns true on success, false on failure (with errors populated)
        def confirm!
          attrs = { confirmed_at: Time.current }
          attrs[:temporary] = false if respond_to?(:temporary?)

          if reconfirming?
            # Email change confirmation - check email uniqueness first
            if self.class.where.not(id: id).exists?(email: unconfirmed_email)
              errors.add(:email, 'is already taken by another user')
              return false
            end
            attrs[:email] = unconfirmed_email
            attrs[:unconfirmed_email] = nil
            update(attrs)
          elsif unconfirmed?
            # Initial confirmation
            update(attrs)
          else
            # Already confirmed and not reconfirming
            true
          end
        end

        # Generate email confirmation token using Rails signed_id
        def generate_confirmation_token
          signed_id(
            purpose: :confirm_email,
            expires_in: RailsSimpleAuth.configuration.confirmation_expiry
          )
        end
      end
    end
  end
end
