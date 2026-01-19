# RailsSimpleAuth vs Devise: Choosing the Right Authentication for Rails 8+

RailsSimpleAuth is an opinionated authentication backend built on top of Rails native auth generators, initially to power my personal projects. I decided to share it because I think the authentication generators in Rails are great, but I still have to reuse code from project to project, so I created a gem that follows my approach to auth.

But you all want to know how it compares to Devise, right? So I asked Claude to prepare this comparison, because I personally never used Devise and was thinking it's too complex for my cases.

## Quick Comparison

| Aspect | RailsSimpleAuth | Devise |
|--------|-----------------|--------|
| **Philosophy** | Explicit, minimal, Rails-native | Full-featured, convention-heavy |
| **Dependencies** | None (Rails only) | Warden, bcrypt, responders |
| **Codebase size** | ~1,500 lines | ~15,000+ lines |
| **Rails version** | 8.0+ | 7.0+ |
| **Learning curve** | Low | Moderate to High |

## Feature-by-Feature Breakdown

### Core Authentication

Both gems handle the basics well:

| Feature | RailsSimpleAuth | Devise |
|---------|:---------------:|:------:|
| Email/Password login | ✅ | ✅ |
| Email confirmation | ✅ | ✅ |
| Password reset | ✅ | ✅ |
| Session management | ✅ | ✅ |

### Where They Differ

| Feature | RailsSimpleAuth | Devise |
|---------|:---------------:|:------:|
| **Magic link authentication** | ✅ Built-in | ❌ Requires gem |
| **Temporary/Guest users** | ✅ Built-in | ❌ Manual implementation |
| **Rate limiting** | ✅ Rails 8 DSL | ❌ Rack::Attack or manual |
| **Session duration** | ✅ Configurable (default 30 days) | ✅ Rememberable module |
| **Account lockout** | ❌ | ✅ Lockable module |
| **Login attempt tracking** | ✅ IP/User-agent per session | ✅ Trackable module |
| **Multiple user types** | ✅ Single table with role column | ✅ Separate scopes |
| **Admin functionality** | ✅ Simple `admin?` method | ✅ Separate Admin model |

### Modern Features

RailsSimpleAuth includes features that reflect modern authentication patterns:

**Magic Links** — Passwordless authentication via email, increasingly popular for reducing friction:

```ruby
# RailsSimpleAuth - built in
RailsSimpleAuth.configure do |config|
  config.magic_link_enabled = true
  config.magic_link_expiry = 15.minutes
end
```

```ruby
# Devise - requires additional gem (devise-passwordless)
# Plus configuration and custom controllers
```

**Temporary Users** — Guest accounts that convert to permanent, ideal for try-before-signup flows:

```ruby
# RailsSimpleAuth - built in
user = User.create!(temporary: true, ...)
# Later...
user.convert_to_permanent!(email: "real@email.com", password: "secure123")
```

```ruby
# Devise - manual implementation required
# Create guest user model, handle conversion, clean up orphans...
```

**Rate Limiting** — Protection against brute force attacks using Rails 8's native DSL:

```ruby
# RailsSimpleAuth - built in, configurable
config.rate_limits = {
  sign_in: { limit: 5, period: 15.minutes },
  password_reset: { limit: 3, period: 1.hour }
}
```

```ruby
# Devise - typically requires Rack::Attack gem
# config/initializers/rack_attack.rb
Rack::Attack.throttle("logins/ip", limit: 5, period: 20.minutes) do |req|
  req.ip if req.path == "/users/sign_in" && req.post?
end
```

## Architecture Comparison

### How Sessions Work

**RailsSimpleAuth** uses a dedicated `sessions` table with explicit tracking:

```ruby
# Each login creates a database record
create_table :sessions do |t|
  t.references :user, null: false
  t.string :ip_address
  t.string :user_agent
  t.timestamps
end

# Session token stored in signed cookie
cookies.signed.permanent[:session_token] = {
  value: session_record.id,
  httponly: true,
  same_site: :lax
}
```

**Devise** uses Warden middleware with Rails session storage:

```ruby
# Warden stores user ID in Rails session
# Session data stored in cookies or database (depending on Rails config)
warden.set_user(user, scope: :user)

# Retrieval happens through Warden
current_user # => calls warden.user(:user)
```

### Password Handling

**RailsSimpleAuth** uses Rails' built-in `has_secure_password`:

```ruby
class User < ApplicationRecord
  has_secure_password  # Uses bcrypt internally
end
```

**Devise** implements its own password handling through the `database_authenticatable` module, also using bcrypt but with additional configuration options.

### Token Generation

**RailsSimpleAuth** uses Rails' `MessageVerifier` for signed, expiring tokens:

```ruby
# Tokens are signed and include expiration
token = Rails.application.message_verifier(:password_reset)
  .generate(user.id, expires_in: 15.minutes)
```

**Devise** generates random tokens stored in the database:

```ruby
# Random token stored in reset_password_token column
user.reset_password_token = SecureRandom.hex(20)
user.reset_password_sent_at = Time.current
user.save
```

## Code Complexity

### Controller Implementation

**RailsSimpleAuth** — straightforward Rails controllers:

```ruby
class RailsSimpleAuth::SessionsController < RailsSimpleAuth::BaseController
  def create
    user = User.find_by(email: params[:email])

    if user&.authenticate(params[:password])
      create_session_for(user)
      redirect_to after_sign_in_path
    else
      flash.now[:alert] = "Invalid email or password"
      render :new, status: :unprocessable_entity
    end
  end
end
```

**Devise** — callback-heavy inherited controllers:

```ruby
class Devise::SessionsController < DeviseController
  prepend_before_action :require_no_authentication, only: [:new, :create]
  prepend_before_action :allow_params_authentication!, only: :create
  prepend_before_action :verify_signed_out_user, only: :destroy
  prepend_before_action only: [:create, :destroy] { request.env["devise.skip_timeout"] = true }

  def create
    self.resource = warden.authenticate!(auth_options)
    set_flash_message!(:notice, :signed_in)
    sign_in(resource_name, resource)
    yield resource if block_given?
    respond_with resource, location: after_sign_in_path_for(resource)
  end
end
```

### Customization Approach

**RailsSimpleAuth** — subclass and override:

```ruby
class SessionsController < RailsSimpleAuth::SessionsController
  def after_sign_in(user)
    Analytics.track("sign_in", user_id: user.id)
    super
  end
end

# routes.rb
rails_simple_auth_routes(sessions_controller: "sessions")
```

**Devise** — callbacks and configuration:

```ruby
class Users::SessionsController < Devise::SessionsController
  after_action :after_login, only: :create

  private

  def after_login
    Analytics.track("sign_in", user_id: current_user.id)
  end
end

# routes.rb
devise_for :users, controllers: { sessions: "users/sessions" }
```

## Setup Comparison

### RailsSimpleAuth Setup

```bash
# 1. Add gem
bundle add rails_simple_auth

# 2. Run installer
rails generate rails_simple_auth:install
rails db:migrate

# 3. Add authentication to User model
```

```ruby
class User < ApplicationRecord
  authenticates_with :confirmable, :magic_linkable, :oauth, :temporary
end
```

### Devise Setup

```bash
# 1. Add gem
bundle add devise

# 2. Run installer
rails generate devise:install
rails generate devise User
rails db:migrate

# 3. Configure initializer (50+ options)
# 4. Add mailer config, root route, flash messages...
```

```ruby
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :timeoutable, :trackable
end
```

## When to Choose Each

### Choose RailsSimpleAuth When:

- **Building a new Rails 8+ application** — Take advantage of Rails-native patterns
- **You want to understand your auth code** — ~1,500 lines vs ~15,000+
- **You need magic links or temporary users** — Built-in, not bolted on
- **Minimal dependencies matter** — Zero external gems
- **You prefer explicit over convention** — No Warden middleware layer
- **Building for modern web** — Rate limiting, signed tokens, secure defaults

### Choose Devise When:

- **Account lockout is required** — Lock after N failed attempts
- **Completely separate user models** — Different tables for Admin vs User
- **Your team already knows Devise** — Familiarity reduces onboarding time
- **You need extensive documentation** — 10+ years of Stack Overflow answers
- **Battle-tested is paramount** — Powers millions of applications

### Session Duration Philosophy

**Devise** uses "remember me" checkbox — short sessions by default, longer if user opts in.

**RailsSimpleAuth** uses configurable session expiration for everyone (default 30 days):

```ruby
RailsSimpleAuth.configure do |config|
  config.session_expiry = 30.days  # All users get this duration
end
```

This is simpler and matches modern app expectations where users stay logged in. Adjust the duration based on your security requirements.

### Admin Functionality

**Devise** typically uses separate models with different scopes:

```ruby
# Separate tables, separate routes, separate authentication
devise_for :users
devise_for :admins
```

**RailsSimpleAuth** uses a single table with role-based access — the Rails way:

```ruby
# Migration
add_column :users, :admin, :boolean, default: false

# Model
class User < ApplicationRecord
  authenticates_with :confirmable

  def admin?
    admin == true
  end
end

# Controller
class AdminController < ApplicationController
  before_action :require_admin

  private

  def require_admin
    redirect_to root_path, alert: "Not authorized" unless current_user&.admin?
  end
end
```

This approach is simpler, avoids duplicate authentication logic, and follows Rails conventions. For more complex role systems, add a `role` column or use a gem like Pundit for authorization.

## Migration Guide: Devise to RailsSimpleAuth

If you're considering switching, here's a high-level migration path:

### 1. Database Compatibility

Both use `password_digest`, so existing passwords work:

```ruby
# Devise
t.string :encrypted_password  # Actually bcrypt digest

# RailsSimpleAuth
t.string :password_digest     # Same bcrypt format

# Migration
rename_column :users, :encrypted_password, :password_digest
```

### 2. Model Changes

```ruby
# Before (Devise)
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :confirmable
end

# After (RailsSimpleAuth)
class User < ApplicationRecord
  authenticates_with :confirmable
end
```

### 3. Helper Method Mapping

| Devise | RailsSimpleAuth |
|--------|-----------------|
| `current_user` | `current_user` |
| `user_signed_in?` | `user_signed_in?` |
| `authenticate_user!` | `require_authentication` |
| `sign_in(user)` | `create_session_for(user)` |
| `sign_out` | `destroy_current_session` |

### 4. Route Changes

```ruby
# Before
devise_for :users

# After
rails_simple_auth_routes
```

## Performance Considerations

**RailsSimpleAuth:**
- Single database query per request (session lookup)
- No middleware overhead
- Sessions stored in dedicated table with indexes

**Devise:**
- Warden middleware runs on every request
- Session serialization/deserialization overhead
- More flexible but slightly more complex request cycle

For most applications, the difference is negligible. Choose based on features and developer experience, not performance.

## Conclusion

The choice between RailsSimpleAuth and Devise isn't about which is "better"—it's about which fits your needs.

**RailsSimpleAuth** represents the Rails 8 philosophy: simple, explicit, built on primitives. It includes modern features like magic links, temporary users, and rate limiting out of the box. You can read and understand the entire codebase in an afternoon.

**Devise** remains the comprehensive solution with a decade of battle-testing. If you need account lockout or completely separate authentication models (different tables for Admin vs User), Devise delivers these without custom code.

For new Rails 8+ projects prioritizing simplicity and modern authentication patterns, RailsSimpleAuth offers a compelling alternative. For complex requirements or teams experienced with Devise, the incumbent remains a solid choice.

The best authentication is the one your team understands and can maintain. Choose accordingly.

---

## Resources

- [RailsSimpleAuth on GitHub](https://github.com/ivankuznetsov/rails_simple_auth)
- [Devise on GitHub](https://github.com/heartcombo/devise)
- [Rails 8 Authentication Guide](https://guides.rubyonrails.org/security.html)
- [Warden Documentation](https://github.com/wardencommunity/warden/wiki)
