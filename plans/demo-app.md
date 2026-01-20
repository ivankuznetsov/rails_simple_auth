# feat: Minimal Demo App for rails_simple_auth

## Overview

Create a minimal Rails demo application in a separate folder that demonstrates the rails_simple_auth gem. The app will maximally rely on the gem's defaults, using generators and default styling without custom functionality.

## Decision Summary (Keeping It Minimal)

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Modules | `:confirmable`, `:magic_linkable` | Core auth features, no OAuth complexity |
| OAuth | Disabled | Requires external setup, not minimal |
| Temporary Users | Disabled | Advanced feature, not minimal |
| Database | SQLite | Zero configuration |
| Email | letter_opener | View emails in browser, no SMTP setup |
| Styling | gem CSS generator | Use `.rsa-` BEM classes |
| Tests | None | Demo only, not a test suite |
| Deployment | None | Local development only |

## Acceptance Criteria

- [ ] New Rails app created in `../rails_simple_auth_demo/`
- [ ] Uses rails_simple_auth gem via local path
- [ ] Runs `rails_simple_auth:install` generator
- [ ] Runs `rails_simple_auth:css` generator
- [ ] User model with `authenticates_with :confirmable, :magic_linkable`
- [ ] Public landing page with sign in/sign up links
- [ ] Protected dashboard showing current user
- [ ] All auth flows work: sign up, confirm, sign in, sign out, password reset, magic link
- [ ] Emails viewable via letter_opener

## MVP Implementation

### Step 1: Create Rails App

```bash
cd /home/asterio/Dev
rails new rails_simple_auth_demo --skip-test
cd rails_simple_auth_demo
```

### Step 2: Update Gemfile

```ruby
# Gemfile
gem "rails_simple_auth", path: "../rails_simple_auth"
gem "letter_opener", group: :development
```

### Step 3: Run Generators

```bash
bundle install
rails generate rails_simple_auth:install
rails generate rails_simple_auth:css
```

### Step 4: Create User Model

#### db/migrate/xxx_create_users.rb

```ruby
class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :password_digest, null: false
      t.datetime :confirmed_at
      t.string :unconfirmed_email
      t.timestamps
    end
    add_index :users, :email, unique: true
  end
end
```

#### app/models/user.rb

```ruby
class User < ApplicationRecord
  authenticates_with :confirmable, :magic_linkable
end
```

### Step 5: Create Controllers

#### app/controllers/application_controller.rb

```ruby
class ApplicationController < ActionController::Base
  allow_browser versions: :modern
end
```

#### app/controllers/home_controller.rb

```ruby
class HomeController < ApplicationController
  def index
    redirect_to dashboard_path if user_signed_in?
  end
end
```

#### app/controllers/dashboard_controller.rb

```ruby
class DashboardController < ApplicationController
  before_action :require_authentication

  def show
  end
end
```

### Step 6: Create Views

#### app/views/home/index.html.erb

```erb
<div class="rsa-container">
  <div class="rsa-auth-form">
    <h1 class="rsa-auth-form__title">rails_simple_auth Demo</h1>
    <p style="text-align: center; margin-bottom: 1.5rem; color: #666;">
      A minimal authentication gem for Rails
    </p>
    <div style="display: flex; flex-direction: column; gap: 0.75rem;">
      <%= link_to "Sign In", new_session_path, class: "rsa-auth-form__submit" %>
      <%= link_to "Sign Up", new_registration_path, class: "rsa-auth-form__submit", style: "background: #6b7280;" %>
    </div>
  </div>
</div>
```

#### app/views/dashboard/show.html.erb

```erb
<div class="rsa-container">
  <div class="rsa-auth-form">
    <h1 class="rsa-auth-form__title">Dashboard</h1>
    <p style="text-align: center; margin-bottom: 1rem;">
      Welcome, <strong><%= current_user.email %></strong>
    </p>
    <p style="text-align: center; color: #666; margin-bottom: 1.5rem;">
      You are signed in.
    </p>
    <%= button_to "Sign Out", session_path, method: :delete, class: "rsa-auth-form__submit", style: "background: #dc2626;" %>
  </div>
</div>
```

#### app/views/layouts/application.html.erb

```erb
<!DOCTYPE html>
<html>
  <head>
    <title>rails_simple_auth Demo</title>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>
    <%= stylesheet_link_tag "rails_simple_auth", "data-turbo-track": "reload" %>
    <%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
    <%= javascript_importmap_tags %>
  </head>
  <body>
    <%= yield %>
  </body>
</html>
```

### Step 7: Configure Routes

#### config/routes.rb

```ruby
Rails.application.routes.draw do
  rails_simple_auth_routes

  root "home#index"
  get "dashboard", to: "dashboard#show"
end
```

### Step 8: Configure Email Delivery

#### config/environments/development.rb

Add to the file:

```ruby
config.action_mailer.delivery_method = :letter_opener
config.action_mailer.perform_deliveries = true
config.action_mailer.default_url_options = { host: "localhost", port: 3000 }
```

### Step 9: Run Migrations and Start

```bash
rails db:migrate
rails server
```

## File Structure

```
rails_simple_auth_demo/
├── app/
│   ├── controllers/
│   │   ├── application_controller.rb
│   │   ├── home_controller.rb
│   │   └── dashboard_controller.rb
│   ├── models/
│   │   └── user.rb
│   └── views/
│       ├── layouts/
│       │   └── application.html.erb
│       ├── home/
│       │   └── index.html.erb
│       └── dashboard/
│           └── show.html.erb
├── config/
│   ├── routes.rb
│   ├── environments/
│   │   └── development.rb (modified)
│   └── initializers/
│       └── rails_simple_auth.rb (generated)
├── db/
│   └── migrate/
│       ├── xxx_create_users.rb
│       └── xxx_add_rails_simple_auth.rb (generated)
├── Gemfile
└── README.md
```

## User Flows Supported

1. **Sign Up**: Visit `/sign_up` → Enter email/password → Email confirmation sent → Click link → Confirmed
2. **Sign In**: Visit `/session/new` → Enter credentials → Redirected to dashboard
3. **Sign Out**: Click "Sign Out" on dashboard → Redirected to sign in
4. **Password Reset**: Visit `/passwords/new` → Enter email → Click email link → Set new password
5. **Magic Link**: Visit `/magic_link_form` → Enter email → Click email link → Signed in

## README.md

```markdown
# rails_simple_auth Demo

Minimal demo application for the [rails_simple_auth](https://github.com/ivankuznetsov/rails_simple_auth) gem.

## Setup

```bash
git clone <this-repo>
cd rails_simple_auth_demo
bundle install
rails db:migrate
rails server
```

Visit http://localhost:3000

## Features Demonstrated

- Email/password sign up with confirmation
- Sign in / Sign out
- Password reset via email
- Magic link (passwordless) authentication

## Email Delivery

Emails open automatically in your browser via letter_opener.

## Requirements

- Ruby 3.3+
- Rails 8.0+
```

## References

- rails_simple_auth generators: `lib/generators/rails_simple_auth/`
- CSS generator output: `app/assets/stylesheets/rails_simple_auth.css`
- Default views: `app/views/rails_simple_auth/`
- Routes helper: `lib/rails_simple_auth/routes.rb`
- Model integration: `lib/rails_simple_auth/model.rb:4`
