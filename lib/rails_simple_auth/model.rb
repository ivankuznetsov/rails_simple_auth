# frozen_string_literal: true

module RailsSimpleAuth
  module Model
    extend ActiveSupport::Concern

    MODULES = {
      confirmable: 'RailsSimpleAuth::Models::Concerns::Confirmable',
      magic_linkable: 'RailsSimpleAuth::Models::Concerns::MagicLinkable',
      oauth: 'RailsSimpleAuth::Models::Concerns::OAuthConnectable',
      temporary: 'RailsSimpleAuth::Models::Concerns::TemporaryUser'
    }.freeze

    class_methods do
      # Configure authentication for this model
      #
      # @example Basic authentication only
      #   authenticates_with
      #
      # @example With optional modules
      #   authenticates_with :confirmable, :magic_linkable
      #
      # @example Full featured
      #   authenticates_with :confirmable, :magic_linkable, :oauth, :temporary
      #
      # Available modules:
      # - :confirmable     - Email confirmation for new accounts
      # - :magic_linkable  - Passwordless sign-in via email
      # - :oauth           - OAuth provider support (Google, GitHub, etc.)
      # - :temporary       - Guest accounts that convert to permanent
      #
      def authenticates_with(*modules)
        # Always include base authentication
        include RailsSimpleAuth::Models::Concerns::Authenticatable

        # Include requested optional modules
        modules.each do |mod|
          mod_name = mod.to_sym
          unless MODULES.key?(mod_name)
            raise ArgumentError, "Unknown authentication module: #{mod.inspect}. " \
                                 "Available modules: #{MODULES.keys.join(', ')}"
          end

          include MODULES[mod_name].constantize
        end
      end
    end
  end
end
