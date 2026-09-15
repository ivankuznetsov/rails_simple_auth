# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.2.1] - 2026-09-15

### Fixed

- OAuth linking reloads the account under a row lock so concurrent confirmation or pending email changes are preserved; if the matched email changes before linking, sign-in is rejected.
- Confirm existing accounts when linking by email through a trusted OAuth provider, before calling the host application's `assign_oauth_attributes` hook. Preserve existing confirmation timestamps and pending email changes. Accounts found by provider and UID remain unchanged.
- Return `nil` when saving an existing OAuth account link fails, preventing authentication with unsaved changes.

## [1.2.0] - 2026-05-23

### Changed

- **OAuth provider sign-in now honors `session[:return_to]`.** `OmniauthCallbacksController#create` previously hardcoded `after_sign_in_path`, so a user mid-redirect (e.g., a host app that called `store_location_for_redirect` before bouncing to `/sign_in`) landed on the default page after the Google/GitHub round-trip instead of resuming. It now goes through `sign_in_user_and_redirect`, which consumes `session[:return_to]` and falls back to `after_sign_in_path`. **Action:** host apps relying on a hard reset to the configured path post-OAuth should review their flows; the configured path remains the default when nothing was stored.
- **Confirmation-disabled sign-up now honors `session[:return_to]`.** `RegistrationsController#after_successful_registration`'s no-confirmation branch previously hardcoded `after_sign_up_path`. It now redirects to `stored_location_or_default(:after_sign_up_path)` — same precedence rule, separate config key. The `after_sign_up_callback` execution path is unchanged.
- **`stored_location_or_default` now accepts an optional fallback config key** (default `:after_sign_in_path`), so callers can pass `:after_sign_up_path` (or any other configured path) without duplicating the lookup logic.
- **`stored_location_or_default` validates the stored value at read time** as defense-in-depth: a poisoned `session[:return_to]` (non-string, doesn't start with `/`, or starts with `//`) is rejected and the fallback is used instead. The write-side validation in `store_location_for_redirect` remains the primary defense; this read-side check protects host apps that bypass the helper.
- **Extracted `sign_in_user_and_redirect(user, notice:)` to `SessionManagement` concern.** `SessionsController#sign_in_and_redirect` and `OmniauthCallbacksController#create` now share one definition of the sign-in-and-redirect sequence (`destroy_temporary_user_session` → `create_session_for` → `run_after_sign_in_callback` → `redirect_to stored_location_or_default`). `SessionsController#sign_in_and_redirect`'s external behavior is preserved.

## [1.1.0] - 2026-01-20

### Added

- **Generator E2E test infrastructure** - CI pipeline now validates that generators produce working views
  - `bin/test_generator` script creates fresh Rails app, runs generators, and executes E2E tests
  - Reusable Page Object test templates in `test/generator_test_files/`
  - GitHub Actions `generator-test` job runs after unit tests pass
- **Local CI script** - `bin/ci` for running lint and tests locally before pushing

### Fixed

- **Session model autoloading** - Moved `RailsSimpleAuth::Session` from `lib/` to `app/models/` for proper Rails engine autoloading
- **CSS form alignment** - Fixed inconsistent margins on form inputs and buttons

## [1.0.14] - 2026-01-20

### Fixed

- **Rails 8.1 generator compatibility** - Renamed `create_migration` method to `copy_migration_file` in install generator to avoid conflict with Rails 8.1's internal migration generator methods

## [1.0.13] - 2026-01-19

### Fixed

- **OAuth controller uses display names** - Success and failure messages now use `oauth_provider_display_name` instead of raw provider name

## [1.0.12] - 2026-01-19

### Added

- **OAuth view helper** - Simple `oauth_display_name(provider)` helper for views
  ```erb
  Continue with <%= oauth_display_name(provider) %>
  ```

## [1.0.11] - 2026-01-19

### Added

- **OAuth provider display names** - Configure human-readable names for OAuth buttons
  ```ruby
  # Hash format with custom display names
  config.enable_oauth(google_oauth2: "Google", github: "GitHub")

  # Symbol format still works (backward compatible)
  config.enable_oauth(:google_oauth2, :github)
  ```
- `oauth_provider_display_name(provider)` method returns the display name, falling back to titleized provider name with `_oauth2` suffix removed

## [1.0.10] - 2026-01-19

### Fixed

- **OAuth authenticity token error** - Disabled OmniAuth's `AuthenticityTokenProtection` which was blocking OAuth requests even with valid CSRF tokens. POST-only enforcement already prevents CSRF attacks.

## [1.0.9] - 2026-01-19

### Added

- **OAuth failure logging** - Logs error type, strategy, and error message when OAuth fails to help debug authentication issues

## [1.0.8] - 2026-01-19

### Fixed

- **OAuth buttons use button_to instead of link_to** - `link_to` with `method: :post` doesn't work in Rails 8 without rails-ujs. Changed OAuth buttons in sessions and registrations views to use `button_to` which properly creates POST forms.

## [1.0.7] - 2026-01-19

### Fixed

- **Temporary users can now access sign-in page** - Previously, temporary users clicking "Sign in" were redirected away because `user_signed_in?` returned true. Now checks `permanent_user_signed_in?` instead, allowing temporary users to sign in with a real account.

### Added

- **Referrer-based redirect after sign-in** - When users voluntarily click "Sign in" (not forced by `require_authentication`), their referring page is stored so they're redirected back after signing in. Security: only stores referrer from same origin.
- `permanent_user_signed_in?` helper method - Returns true only if user is signed in AND permanent (or doesn't respond to `permanent?`)

## [1.0.6] - 2025-01-19

### Added

- **Database-level email uniqueness** - Partial unique index ensures permanent users have unique emails at database level (not just Rails validation)

### Changed

- Simplified `temporary?` method for cleaner implementation

## [1.0.5] - 2025-01-19

### Added

- **Secure OmniAuth by default** - Automatically restricts OAuth initiation to POST requests only (prevents CSRF attacks)

## [1.0.4] - 2025-01-19

### Added

- **`authenticates_with` DSL** - Cleaner model setup inspired by Devise syntax
  ```ruby
  # Before
  include RailsSimpleAuth::Models::Concerns::Authenticatable
  include RailsSimpleAuth::Models::Concerns::Confirmable

  # After
  authenticates_with :confirmable, :magic_linkable, :oauth, :temporary
  ```
- **Devise comparison article** - Comprehensive comparison at `docs/devise-comparison.md`
- **Admin Users documentation** - Guide for implementing admin functionality
- **Rate Limiting documentation** - Default limits and customization guide
- **Session Management documentation** - Expiration, querying, and cleanup

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
