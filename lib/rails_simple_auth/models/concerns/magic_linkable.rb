# frozen_string_literal: true

module RailsSimpleAuth
  module Models
    module Concerns
      module MagicLinkable
        extend ActiveSupport::Concern

        # No additional columns required - uses signed_id

        # Generate magic link token using Rails signed_id
        def generate_magic_link_token
          signed_id(
            purpose: :magic_link,
            expires_in: RailsSimpleAuth.configuration.magic_link_expiry
          )
        end
      end
    end
  end
end
