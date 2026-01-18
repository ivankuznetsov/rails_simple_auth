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
        def confirm!
          if reconfirming?
            # Email change confirmation
            update!(
              email: unconfirmed_email,
              unconfirmed_email: nil,
              confirmed_at: Time.current
            )
          elsif unconfirmed?
            # Initial confirmation
            update!(confirmed_at: Time.current)
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
