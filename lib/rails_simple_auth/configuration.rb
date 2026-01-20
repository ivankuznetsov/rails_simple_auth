# frozen_string_literal: true

module RailsSimpleAuth
  class Configuration
    attr_accessor :magic_link_enabled, :email_confirmation_enabled, :oauth_enabled, :oauth_providers, :oauth_provider_names, :oauth_link_existing_accounts,
                  :magic_link_expiry, :password_reset_expiry, :confirmation_expiry, :session_expiry,
                  :rate_limits,
                  :after_sign_in_path, :after_sign_out_path, :after_sign_up_path, :after_confirmation_path,
                  :layout, :app_name,
                  :mailer_sender, :mailer_class,
                  :user_class_name, :session_class_name,
                  :password_minimum_length,
                  :after_sign_in_callback, :after_sign_out_callback, :after_sign_up_callback, :after_confirmation_callback,
                  :temporary_users_enabled

    attr_reader :temporary_user_cleanup_days

    def initialize
      @magic_link_enabled = true
      @email_confirmation_enabled = true
      @oauth_enabled = false
      @oauth_providers = []
      @oauth_provider_names = {}
      @oauth_link_existing_accounts = true # Allow OAuth to link to existing email accounts

      @magic_link_expiry = 15.minutes
      @password_reset_expiry = 15.minutes
      @confirmation_expiry = 24.hours
      @session_expiry = 30.days

      @rate_limits = {
        sign_in: { limit: 5, period: 15.minutes },
        sign_up: { limit: 5, period: 1.hour },
        magic_link: { limit: 3, period: 10.minutes },
        password_reset: { limit: 3, period: 1.hour },
        confirmation: { limit: 3, period: 1.hour }
      }

      @after_sign_in_path = :root_path
      @after_sign_out_path = :new_session_path
      @after_sign_up_path = :root_path
      @after_confirmation_path = :new_session_path

      @layout = 'rails_simple_auth'
      @app_name = nil

      @mailer_sender = 'noreply@example.com'
      @mailer_class = 'RailsSimpleAuth::AuthMailer'

      @user_class_name = 'User'
      @session_class_name = 'RailsSimpleAuth::Session'

      @password_minimum_length = 8

      @after_sign_in_callback = nil
      @after_sign_out_callback = nil
      @after_sign_up_callback = nil
      @after_confirmation_callback = nil

      @temporary_users_enabled = false
      @temporary_user_cleanup_days = 7
    end

    def user_class
      user_class_name.constantize
    rescue NameError => e
      raise ConfigurationError,
            "User class '#{user_class_name}' not found. " \
            "Ensure it's defined and the name is correct in the initializer. " \
            "Original error: #{e.message}"
    end

    def session_class
      session_class_name.constantize
    rescue NameError => e
      raise ConfigurationError,
            "Session class '#{session_class_name}' not found. " \
            "Ensure it's defined and the name is correct in the initializer. " \
            "Original error: #{e.message}"
    end

    def mailer
      mailer_class.constantize
    rescue NameError => e
      raise ConfigurationError,
            "Mailer class '#{mailer_class}' not found. " \
            "Ensure it's defined and the name is correct in the initializer. " \
            "Original error: #{e.message}"
    end

    # Enable OAuth providers with optional display names
    # Usage:
    #   enable_oauth(:google_oauth2, :github)  # Uses default display names
    #   enable_oauth(google_oauth2: "Google", github: "GitHub")  # Custom display names
    def enable_oauth(*providers)
      self.oauth_enabled = true

      if providers.length == 1 && providers.first.is_a?(Hash)
        # Hash format: { google_oauth2: "Google", github: "GitHub" }
        provider_hash = providers.first
        self.oauth_providers = provider_hash.keys.map(&:to_sym)
        self.oauth_provider_names = provider_hash.transform_keys(&:to_sym)
      else
        # Symbol format: :google_oauth2, :github (backward compatible)
        self.oauth_providers = providers.map(&:to_sym)
        self.oauth_provider_names = {}
      end
    end

    def oauth_provider_enabled?(provider)
      oauth_enabled && oauth_providers.include?(provider.to_sym)
    end

    # Get display name for an OAuth provider
    # Falls back to titleized provider name if no custom name is configured
    def oauth_provider_display_name(provider)
      provider_sym = provider.to_sym
      oauth_provider_names[provider_sym] || provider.to_s.gsub(/_oauth2$/, '').titleize
    end

    def rate_limit_for(action)
      rate_limits&.dig(action.to_sym)
    end

    def temporary_user_cleanup_days=(value)
      unless value.is_a?(Integer) && value.positive?
        raise ConfigurationError, 'temporary_user_cleanup_days must be a positive integer'
      end

      @temporary_user_cleanup_days = value
    end
  end
end
