# frozen_string_literal: true

module RailsSimpleAuth
  module OauthHelper
    # Get display name for an OAuth provider
    # Usage: oauth_display_name(:google_oauth2) => "Google"
    def oauth_display_name(provider)
      RailsSimpleAuth.configuration.oauth_provider_display_name(provider)
    end
  end
end
