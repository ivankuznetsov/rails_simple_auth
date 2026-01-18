# frozen_string_literal: true

module RailsSimpleAuth
  module Models
    module Concerns
      module Confirmable
        extend ActiveSupport::Concern

        included do
          # Requires `confirmed_at` datetime column
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

        # Confirm the user's email
        def confirm!
          return true if confirmed?

          update!(confirmed_at: Time.current)
        end

        # Generate email confirmation token using Rails signed_id
        def generate_confirmation_token
          signed_id(
            purpose: :email_confirmation,
            expires_in: RailsSimpleAuth.configuration.confirmation_expiry
          )
        end
      end
    end
  end
end
