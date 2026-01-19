# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.3] - 2025-01-19

### Added

- **Temporary Users Support** - Allow users to try the app without signing up, then convert to permanent accounts
  - `TemporaryUser` concern with `temporary?` and `permanent?` methods
  - Scopes: `temporary`, `permanent`, `temporary_expired`
  - `convert_to_permanent!(email:, password:)` method for account conversion
  - Generator: `rails g rails_simple_auth:temporary_users` for migration
  - Configuration options: `temporary_users_enabled`, `temporary_user_cleanup_days`
  - Automatic cleanup of expired temporary users via `User.cleanup_expired_temporary!`
  - Session invalidation on account conversion
  - Automatic destruction of temporary user when signing in with different account
- **Email Reconfirmation Flow** - Support for users changing their email address
  - `unconfirmed_email` column support for pending email changes
  - `reconfirming?` and `unconfirmed_or_reconfirming?` helper methods
  - `confirmable_email` helper returns the email needing confirmation
  - Confirmation emails sent to new email address during reconfirmation
- Comprehensive test suite (126 tests, 247 assertions)

### Fixed

- `confirm!` now uses `has_attribute?(:temporary)` instead of `respond_to?(:temporary?)` to prevent errors when `Authenticatable` is included without the temporary database column
- `confirm!` properly handles race conditions with `RecordNotUnique` rescue during reconfirmation
- `convert_to_permanent!` validates password presence to prevent users being left without credentials
- `convert_to_permanent!` reloads after transaction to check actual database state (not stale in-memory state)
- `convert_to_permanent!` resets `confirmed_at` to require email verification for new address
- `cleanup_expired_temporary!` now returns accurate count (only increments when destroy succeeds)
- `magic_link_login` checks `confirm!` return value and shows error if confirmation fails
- `confirmations_controller#show` checks `confirm!` return value and displays appropriate error message
- `destroy_temporary_user_session` skips destruction when user is re-authenticating as themselves
- `AuthMailer#confirmation` sends to `confirmable_email` for correct recipient during reconfirmation

### Changed

- Confirmation token purpose changed from `:email_confirmation` to `:confirm_email` (**Breaking**: existing confirmation tokens will be invalidated)

## [1.0.2] - 2025-01-18

### Fixed

- Session invalidation and batch cleanup for temporary users

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
