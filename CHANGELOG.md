# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2025-01-18

### Added

- Initial release extracted from [Writero](https://github.com/ivankuznetsov/writero)
- Session-based authentication with `has_secure_password`
- Magic link authentication (passwordless login via email)
- Email confirmation flow for new registrations
- Password reset flow with secure tokens
- OAuth support (Google, GitHub) via OmniAuth
- Rate limiting on authentication endpoints (Rails 8 rate_limit DSL)
- Configurable callbacks (`after_sign_in_callback`, `after_sign_out_callback`, etc.)
- Configurable redirect paths (`after_sign_in_path`, `after_sign_out_path`, etc.)
- Views generator (`rails g rails_simple_auth:views`) for customization
- CSS generator (`rails g rails_simple_auth:css`) for styling
- Install generator (`rails g rails_simple_auth:install`) for setup
- Session management with automatic cleanup of expired sessions
- Current user tracking via `RailsSimpleAuth::Current`
- Comprehensive security measures:
  - Open redirect prevention
  - Configurable OAuth account linking
  - Secure signed tokens for password reset and magic links
  - Session invalidation on password change
