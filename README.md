# RailsSimpleAuth

Simple, secure authentication for Rails 8+ applications. Built on Rails primitives with no magic.

**Coming from Devise?** Read our [detailed comparison](docs/devise-comparison.md).

## Features

- [**Email/Password authentication**](#installation) - secure session-based auth
- [**Magic link authentication**](#routes) - passwordless sign-in via email
- [**Email confirmation**](#routes) - verify user email addresses
- [**Password reset**](#routes) - secure password recovery flow
- [**OAuth support**](#oauth-setup) - Google, GitHub, and more
- [**Temporary users**](#temporary-users-guest-accounts) - guest accounts that convert to permanent
- [**Rate limiting**](#rate-limiting) - built-in protection on all endpoints
- [**Session tracking**](#session-management) - IP and user agent logging
- [**Customizable styling**](#styling) - CSS variables for easy theming
- [**Custom mailers**](#mailer) - use your own branded email templates

## Installation

Add to your Gemfile:

```ruby
gem "rails_simple_auth"
```

Then run:

```bash
bundle install
```

Run the installer:

```bash
rails generate rails_simple_auth:install
rails db:migrate
```

Add authentication to your User model:

```ruby
class User < ApplicationRecord
  authenticates_with :confirmable, :magic_linkable, :oauth, :temporary

  # Your custom fields and validations
  validates :company_name, presence: true
end
```

Available modules:
- `:confirmable` - Email confirmation for new accounts
- `:magic_linkable` - Passwordless sign-in via email
- `:oauth` - OAuth provider support (Google, GitHub, etc.)
- `:temporary` - Guest accounts that convert to permanent

For basic email/password auth only:

```ruby
class User < ApplicationRecord
  authenticates_with
end
```

Protect your routes:

```ruby
class ApplicationController < ActionController::Base
  before_action :require_authentication
end
```

## User Model Customization

The gem doesn't own your User model—you do. Add any custom fields:

```ruby
# db/migrate/xxx_create_users.rb
class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      # Required by gem
      t.string :email, null: false
      t.string :password_digest, null: false
      t.datetime :confirmed_at  # if using Confirmable

      # Your custom fields
      t.string :name
      t.string :company_name
      t.boolean :admin, default: false
      t.string :oauth_provider
      t.string :oauth_uid

      t.timestamps
    end

    add_index :users, :email, unique: true
  end
end
```

## Styling

The gem ships with **no CSS by default** (Option B). Generate base styles:

```bash
rails generate rails_simple_auth:css
```

Then customize by overriding CSS variables:

```css
/* In your application.css */
:root {
  --rsa-color-primary: #22c55e;        /* Your brand color */
  --rsa-color-background-form: #f0fdf4; /* Form background */
  --rsa-color-text: #166534;           /* Text color */
}
```

Or edit `rails_simple_auth.css` directly for complete control.

### CSS Variables Reference

| Variable | Default | Description |
|----------|---------|-------------|
| `--rsa-color-primary` | `#4f46e5` | Primary button/link color |
| `--rsa-color-primary-hover` | `#4338ca` | Primary hover state |
| `--rsa-color-background-form` | `#ffffff` | Form container background |
| `--rsa-color-text` | `#475569` | Main text color |
| `--rsa-color-text-muted` | `#64748b` | Secondary text color |
| `--rsa-color-border` | `#e2e8f0` | Border color |
| `--rsa-color-danger` | `#dc2626` | Error message color |

## View Customization

Copy views for full customization:

```bash
rails generate rails_simple_auth:views

# Or specific views only
rails generate rails_simple_auth:views --only sessions passwords
```

Views use BEM naming: `.rsa-auth-form`, `.rsa-auth-form__input`, etc.

## Configuration

```ruby
# config/initializers/rails_simple_auth.rb
RailsSimpleAuth.configure do |config|
  # Features
  config.magic_link_enabled = true
  config.email_confirmation_enabled = true
  config.enable_oauth(:google, :github)

  # Token expiration
  config.magic_link_expiry = 15.minutes
  config.password_reset_expiry = 15.minutes
  config.confirmation_expiry = 24.hours

  # Paths (symbol, string, or proc)
  config.after_sign_in_path = :dashboard_path
  config.after_sign_out_path = -> { new_session_path }

  # Layout
  config.layout = "auth"  # Use a custom layout

  # Mailer
  config.mailer_sender = "auth@myapp.com"
  # config.mailer_class = "UserMailer"  # Use custom mailer (optional)

  # Password requirements
  config.password_minimum_length = 12

  # Callbacks
  config.after_sign_in_callback = ->(user, controller) {
    Analytics.track("sign_in", user_id: user.id)
  }
end
```

## OAuth Setup

1. Enable providers:

```ruby
RailsSimpleAuth.configure do |config|
  config.enable_oauth(:google, :github)
end
```

2. Configure OmniAuth:

```ruby
# config/initializers/omniauth.rb
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, ENV["GOOGLE_CLIENT_ID"], ENV["GOOGLE_CLIENT_SECRET"]
  provider :github, ENV["GITHUB_CLIENT_ID"], ENV["GITHUB_CLIENT_SECRET"]
end
```

3. Optionally map OAuth fields:

```ruby
class User < ApplicationRecord
  authenticates_with :oauth

  def assign_oauth_attributes(auth_hash)
    self.name = auth_hash.dig("info", "name")
    self.avatar_url = auth_hash.dig("info", "image")
    self.oauth_provider = auth_hash["provider"]
    self.oauth_uid = auth_hash["uid"]
  end
end
```

Email-based account linking is enabled by default (`config.oauth_link_existing_accounts = true`). Only enable it for providers you trust to supply verified email addresses; the gem does not inspect provider-specific verification claims. Set it to `false` to reject linking by email.

New OAuth accounts and existing accounts linked by email are automatically confirmed when they have a `confirmed_at` column. Existing confirmation timestamps and pending email changes are preserved. Confirmation is assigned before `assign_oauth_attributes`, so your hook can use it to update application-specific state. The hook and confirmation changes are saved together; a failed save returns `nil`.

Accounts found by provider and UID return unchanged, including their email and confirmation state. Applications with historical unconfirmed OAuth accounts should handle their backfill separately.

## Temporary Users (Guest Accounts)

Temporary users allow visitors to try your app without creating an account. They get a real user record with full functionality, then can convert to a permanent account later by providing email and password.

### Why Use Temporary Users?

**Reduce friction**: Let users experience your app's value before asking them to sign up. This is especially useful for:

- **E-commerce**: Users can add items to cart, save preferences, then checkout as guest or create account
- **Productivity apps**: Users can create documents, try features, then save their work by signing up
- **Games**: Users can start playing immediately, then create account to save progress
- **Collaboration tools**: Users can join a shared workspace via link, then register to keep access

**Preserve data**: Unlike anonymous sessions, temporary users have real database records. When they convert, all their data (orders, documents, settings) stays linked to their account.

### Setup

1. Generate the migration:

```bash
rails generate rails_simple_auth:temporary_users
rails db:migrate
```

2. Add the `:temporary` module to your User model:

```ruby
class User < ApplicationRecord
  authenticates_with :confirmable, :temporary
end
```

3. Enable in configuration:

```ruby
RailsSimpleAuth.configure do |config|
  config.temporary_users_enabled = true
  config.temporary_user_cleanup_days = 7  # Auto-cleanup after 7 days
end
```

### Creating Temporary Users

Create a temporary user when someone needs to use your app without signing up:

```ruby
# In your controller
def try_without_account
  user = User.create!(
    email: "temp_#{SecureRandom.hex(8)}@temporary.local",
    password: SecureRandom.hex(32),
    temporary: true
  )

  # Sign them in
  create_session_for(user)
  redirect_to dashboard_path
end
```

Or create via an invite link:

```ruby
def accept_invite
  # Create temporary user to access shared content
  user = User.create!(temporary: true, ...)
  create_session_for(user)
  redirect_to shared_workspace_path(params[:workspace_id])
end
```

### Converting to Permanent Account

When a temporary user is ready to create a real account:

```ruby
# In your controller
def convert_account
  if current_user.convert_to_permanent!(
    email: params[:email],
    password: params[:password]
  )
    redirect_to dashboard_path, notice: "Account created! Please check your email to confirm."
  else
    # Validation failed (email taken, password blank, etc.)
    render :convert_form, status: :unprocessable_entity
  end
end
```

The conversion:
- Updates email and password
- Sets `temporary: false`
- Resets `confirmed_at` (requires email confirmation for new address)
- Invalidates all existing sessions (security measure)
- Sends confirmation email automatically

### What Happens on Sign In?

When a temporary user signs in with a different account (or signs up), the temporary user is automatically destroyed:

```
Temporary User (browsing) → Signs in with existing account → Temp user deleted
Temporary User (browsing) → Creates new account → Temp user deleted
Temporary User (browsing) → Converts their temp account → Keeps same user record
```

This prevents orphaned temporary records and ensures clean data.

### Querying Users

```ruby
User.temporary           # All temporary users
User.permanent           # All permanent users
User.temporary_expired   # Temporary users older than cleanup_days

current_user.temporary?  # Is this a guest?
current_user.permanent?  # Is this a real account?
```

### Cleanup

Temporary users are automatically eligible for cleanup after `temporary_user_cleanup_days`. Run cleanup manually or via scheduled job:

```ruby
# In a rake task or background job
User.cleanup_expired_temporary!

# With custom retention period
User.cleanup_expired_temporary!(days: 14)
```

Add to your scheduler (e.g., `config/recurring.yml` for Solid Queue):

```yaml
cleanup_temporary_users:
  schedule: every day at 3am
  class: CleanupTemporaryUsersJob
```

```ruby
class CleanupTemporaryUsersJob < ApplicationJob
  def perform
    count = User.cleanup_expired_temporary!
    Rails.logger.info "Cleaned up #{count} expired temporary users"
  end
end
```

## Controller Customization

Subclass controllers for custom behavior:

```ruby
# app/controllers/sessions_controller.rb
class SessionsController < RailsSimpleAuth::SessionsController
  def after_sign_in(user)
    track_login(user)
    super
  end
end
```

Update routes to use your controller:

```ruby
rails_simple_auth_routes(sessions_controller: "sessions")
```

## Mailer

The gem includes a built-in mailer (`RailsSimpleAuth::AuthMailer`) with email templates that work out of the box. No configuration required.

### Included Email Templates

| Email | Purpose |
|-------|---------|
| `confirmation` | Email confirmation when user signs up |
| `magic_link` | Passwordless sign-in link |
| `password_reset` | Password recovery link |

### Configuration

```ruby
RailsSimpleAuth.configure do |config|
  # Sender address for all auth emails (required)
  config.mailer_sender = "auth@myapp.com"
  # Or use environment variable
  config.mailer_sender = ENV.fetch("MAILER_FROM", "noreply@example.com")
end
```

### Custom Mailer (Optional)

For branded emails with your own design, use a custom mailer:

```ruby
# config/initializers/rails_simple_auth.rb
RailsSimpleAuth.configure do |config|
  config.mailer_class = "UserMailer"
  config.mailer_sender = "hello@myapp.com"
end
```

Your custom mailer must implement these methods:

```ruby
# app/mailers/user_mailer.rb
class UserMailer < ApplicationMailer
  def confirmation(user, token)
    @user = user
    @confirmation_url = edit_confirmation_url(token: token)
    mail(to: user.email, subject: "Confirm your email")
  end

  def magic_link(user, token)
    @user = user
    @magic_link_url = magic_link_login_url(token: token)
    mail(to: user.email, subject: "Your sign-in link")
  end

  def password_reset(user, token)
    @user = user
    @reset_url = edit_password_url(token: token)
    mail(to: user.email, subject: "Reset your password")
  end
end
```

Create corresponding views in `app/views/user_mailer/`:

```
app/views/user_mailer/
├── confirmation.html.erb
├── magic_link.html.erb
└── password_reset.html.erb
```

## Helpers

Available in controllers and views:

```ruby
current_user          # The signed-in user (or nil)
user_signed_in?       # Boolean
require_authentication # Redirects if not signed in
```

Access anywhere via:

```ruby
RailsSimpleAuth::Current.user
```

## Routes

The gem adds these routes:

| Method | Path | Description |
|--------|------|-------------|
| GET | `/session/new` | Sign in form |
| POST | `/session` | Create session |
| DELETE | `/session` | Sign out |
| GET | `/sign_up` | Sign up form |
| POST | `/sign_up` | Create account |
| GET | `/passwords/new` | Password reset form |
| POST | `/passwords` | Send reset email |
| GET | `/passwords/:token/edit` | New password form |
| PATCH | `/passwords/:token` | Update password |
| GET | `/confirmations/new` | Resend confirmation |
| POST | `/confirmations` | Send confirmation |
| GET | `/confirmations/:token` | Confirm email |
| GET | `/magic_link_form` | Magic link form |
| POST | `/request_magic_link` | Send magic link |
| GET | `/magic_link` | Login via magic link |

## Rate Limiting

All authentication endpoints are rate limited using Rails 8's `rate_limit` DSL to prevent brute force attacks.

### Default Limits

| Action | Limit | Period | Scope |
|--------|-------|--------|-------|
| Sign in | 5 requests | 15 minutes | per IP |
| Sign up | 5 requests | 1 hour | per IP |
| Magic link request | 3 requests | 10 minutes | per email |
| Password reset | 3 requests | 1 hour | per IP |
| Email confirmation | 3 requests | 1 hour | per IP |

### Customizing Limits

```ruby
RailsSimpleAuth.configure do |config|
  config.rate_limits = {
    sign_in: { limit: 10, period: 30.minutes },
    sign_up: { limit: 3, period: 1.hour },
    magic_link: { limit: 5, period: 15.minutes },
    password_reset: { limit: 5, period: 1.hour },
    confirmation: { limit: 5, period: 1.hour }
  }
end
```

### Disabling Rate Limiting

To disable rate limiting for a specific action, set it to `nil`:

```ruby
config.rate_limits = {
  sign_in: nil,  # No rate limiting on sign in
  sign_up: { limit: 5, period: 1.hour }
}
```

When rate limited, users see a "Too many requests" error and must wait for the period to expire.

## Session Management

Sessions track user authentication state with IP address and user agent for security auditing.

### What's Tracked

Each session stores:
- **user_id** - The authenticated user
- **ip_address** - Client IP at sign-in time
- **user_agent** - Browser/device information
- **created_at** - When the session was created

### Session Expiration

Sessions expire after 30 days by default:

```ruby
RailsSimpleAuth.configure do |config|
  config.session_expiry = 30.days  # Default
  # config.session_expiry = 7.days  # Shorter sessions
end
```

### Querying Sessions

```ruby
# All sessions for a user
current_user.sessions

# Recent sessions first
current_user.sessions.recent

# Active sessions (not expired)
current_user.sessions.active

# Expired sessions
current_user.sessions.expired
```

### Session Cleanup

Expired sessions can be cleaned up manually or via scheduled job:

```ruby
# Clean up all expired sessions
RailsSimpleAuth::Session.cleanup_expired!
```

Add to your scheduler:

```ruby
class CleanupExpiredSessionsJob < ApplicationJob
  def perform
    count = RailsSimpleAuth::Session.cleanup_expired!
    Rails.logger.info "Cleaned up #{count} expired sessions"
  end
end
```

### Security Behaviors

- **Password change**: All sessions are invalidated when a user changes their password
- **Account conversion**: All sessions are invalidated when a temporary user converts to permanent
- **Sign out**: Only the current session is destroyed (other devices stay signed in)

## Admin Users

RailsSimpleAuth uses a single table with role-based access — the Rails way. No separate admin models or authentication flows needed.

### Setup

Add an admin column to your users table:

```ruby
# Migration
add_column :users, :admin, :boolean, default: false
```

Add a helper method to your model:

```ruby
class User < ApplicationRecord
  authenticates_with :confirmable

  def admin?
    admin == true
  end
end
```

### Protecting Admin Routes

```ruby
class AdminController < ApplicationController
  before_action :require_admin

  private

  def require_admin
    redirect_to root_path, alert: "Not authorized" unless current_user&.admin?
  end
end

# Or as a concern
module AdminAuthentication
  extend ActiveSupport::Concern

  included do
    before_action :require_admin
  end

  private

  def require_admin
    redirect_to root_path, alert: "Not authorized" unless current_user&.admin?
  end
end
```

### Creating Admin Users

```ruby
# Console
User.find_by(email: "admin@example.com").update!(admin: true)

# Seeds
User.create!(email: "admin@example.com", password: "secure123", admin: true)
```

For more complex role systems, consider adding a `role` enum or using an authorization gem like [Pundit](https://github.com/varvet/pundit).

## Security Features

- **BCrypt password hashing** with salts
- **Constant-time comparison** prevents timing attacks
- **Signed tokens** for all email links
- **Rate limiting** on all auth endpoints
- **HttpOnly cookies** for session tokens
- **SameSite=Lax** CSRF protection
- **Session invalidation** on password change
- **IP and user agent tracking** for audit

## License

MIT License
