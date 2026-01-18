# RailsSimpleAuth

Simple, secure authentication for Rails 8+ applications. Built on Rails primitives with no magic.

## Features

- **Email/Password authentication** with bcrypt
- **Magic link** (passwordless) authentication
- **Email confirmation** with signed tokens
- **Password reset** with signed tokens
- **OAuth support** (Google, GitHub, etc.)
- **Temporary users** (guest mode) with conversion to permanent
- **Rate limiting** built-in
- **Session tracking** with IP and user agent
- **Customizable styling** via CSS variables
- **No dependencies** beyond Rails and bcrypt

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

Add concerns to your User model:

```ruby
class User < ApplicationRecord
  include RailsSimpleAuth::Models::Concerns::Authenticatable
  include RailsSimpleAuth::Models::Concerns::Confirmable      # optional
  include RailsSimpleAuth::Models::Concerns::MagicLinkable    # optional
  include RailsSimpleAuth::Models::Concerns::OAuthConnectable # optional

  # Your custom fields and validations
  validates :company_name, presence: true
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
      t.string :email_address, null: false
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

    add_index :users, :email_address, unique: true
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
| `--rsa-color-primary` | `#3b82f6` | Primary button/link color |
| `--rsa-color-primary-hover` | `#2563eb` | Primary hover state |
| `--rsa-color-background-form` | `#ffffff` | Form container background |
| `--rsa-color-text` | `#374151` | Main text color |
| `--rsa-color-text-muted` | `#6b7280` | Secondary text color |
| `--rsa-color-border` | `#e5e7eb` | Border color |
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
  include RailsSimpleAuth::Models::Concerns::OAuthConnectable

  def assign_oauth_attributes(auth_hash)
    self.name = auth_hash.dig("info", "name")
    self.avatar_url = auth_hash.dig("info", "image")
    self.oauth_provider = auth_hash["provider"]
    self.oauth_uid = auth_hash["uid"]
  end
end
```

## Temporary Users (Guest Mode)

Allow visitors to try your app without signing up, then convert to permanent accounts later.

### Setup

1. Generate the migration:

```bash
rails generate rails_simple_auth:temporary_users
rails db:migrate
```

2. Include the concern in your User model:

```ruby
class User < ApplicationRecord
  include RailsSimpleAuth::Models::Concerns::Authenticatable
  include RailsSimpleAuth::Models::Concerns::TemporaryUser  # Add this
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

```ruby
# Create a temporary user (no email/password required)
temp_user = User.create!(
  email_address: "temp_#{SecureRandom.hex(8)}@temp.local",
  password: SecureRandom.hex(16),
  temporary: true
)
```

### Converting to Permanent Account

```ruby
# When user decides to sign up for real
temp_user.convert_to_permanent!(
  email_address: "real@example.com",
  password: "secure_password"
)
# Sends confirmation email automatically if email confirmation is enabled
```

### Scopes

```ruby
User.temporary          # All temporary users
User.permanent          # All permanent users
User.temporary_expired  # Temporary users older than cleanup_days
User.temporary_expired(14)  # Custom days
```

### Cleanup Task

Add to your scheduler (cron, Sidekiq, etc.):

```ruby
# Delete expired temporary users
User.temporary_expired.destroy_all
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
    mail(to: user.email_address, subject: "Confirm your email")
  end

  def magic_link(user, token)
    @user = user
    @magic_link_url = magic_link_login_url(token: token)
    mail(to: user.email_address, subject: "Your sign-in link")
  end

  def password_reset(user, token)
    @user = user
    @reset_url = edit_password_url(token: token)
    mail(to: user.email_address, subject: "Reset your password")
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
