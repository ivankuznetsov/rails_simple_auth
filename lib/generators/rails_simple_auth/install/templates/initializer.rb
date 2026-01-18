# frozen_string_literal: true

RailsSimpleAuth.configure do |config|
  # ============================================================================
  # Features
  # ============================================================================

  # Enable magic link authentication (passwordless sign in via email)
  config.magic_link_enabled = true

  # Require email confirmation before password login
  # Users can still log in via magic link (which auto-confirms)
  config.email_confirmation_enabled = true

  # Enable OAuth authentication
  # config.enable_oauth(:google, :github)

  # ============================================================================
  # Token Expiration
  # ============================================================================

  config.magic_link_expiry = 15.minutes
  config.password_reset_expiry = 15.minutes
  config.confirmation_expiry = 24.hours
  config.session_expiry = 30.days

  # ============================================================================
  # Rate Limiting
  # ============================================================================

  # Set to nil to disable rate limiting for a specific action
  config.rate_limits = {
    sign_in: { limit: 5, period: 15.minutes },
    sign_up: { limit: 5, period: 1.hour },
    magic_link: { limit: 3, period: 10.minutes },
    password_reset: { limit: 3, period: 1.hour },
    confirmation: { limit: 3, period: 1.hour }
  }

  # ============================================================================
  # Paths
  # ============================================================================

  # Where to redirect after sign in (can be a symbol, string, or proc)
  config.after_sign_in_path = :root_path

  # Where to redirect after sign out
  config.after_sign_out_path = :new_session_path

  # Where to redirect after sign up (when email confirmation is disabled)
  config.after_sign_up_path = :root_path

  # Where to redirect after email confirmation
  config.after_confirmation_path = :new_session_path

  # ============================================================================
  # Layout
  # ============================================================================

  # Layout to use for auth pages (default: "application")
  config.layout = "application"

  # ============================================================================
  # Mailer
  # ============================================================================

  # From address for auth emails
  config.mailer_sender = ENV.fetch("MAILER_FROM", "noreply@example.com")

  # Custom mailer class (must implement confirmation, magic_link, password_reset methods)
  # config.mailer_class = "RailsSimpleAuth::AuthMailer"

  # ============================================================================
  # Models
  # ============================================================================

  # Your user model class name
  config.user_class_name = "<%= options[:user_model] %>"

  # Custom session model (if you want to use your own)
  # config.session_class_name = "RailsSimpleAuth::Session"

  # ============================================================================
  # Password Requirements
  # ============================================================================

  config.password_minimum_length = 8

  # ============================================================================
  # Callbacks
  # ============================================================================

  # Custom logic after sign in (receives user and controller)
  # config.after_sign_in_callback = ->(user, controller) {
  #   Rails.logger.info("User #{user.id} signed in from #{controller.client_ip}")
  # }

  # Custom logic after sign out
  # config.after_sign_out_callback = ->(user, controller) { }

  # Custom logic after sign up
  # config.after_sign_up_callback = ->(user, controller) { }

  # Custom logic after email confirmation
  # config.after_confirmation_callback = ->(user, controller) { }
end
