# frozen_string_literal: true

require_relative 'lib/rails_simple_auth/version'

Gem::Specification.new do |spec|
  spec.name = 'rails_simple_auth'
  spec.version = RailsSimpleAuth::VERSION
  spec.authors = ['Ivan Kuznetsov']
  spec.email = ['ivan@ikuznetsov.com']

  spec.summary = 'Simple, secure authentication for Rails 8+ applications'
  spec.description = 'A lightweight authentication gem built on Rails primitives: has_secure_password, signed cookies, rate limiting. Supports email/password, magic links, email confirmation, and OAuth.'
  spec.homepage = 'https://github.com/ivankuznetsov/rails_simple_auth'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.2.0'

  spec.metadata = {
    'homepage_uri' => spec.homepage,
    'source_code_uri' => 'https://github.com/ivankuznetsov/rails_simple_auth',
    'changelog_uri' => 'https://github.com/ivankuznetsov/rails_simple_auth/blob/main/CHANGELOG.md',
    'bug_tracker_uri' => 'https://github.com/ivankuznetsov/rails_simple_auth/issues',
    'documentation_uri' => 'https://github.com/ivankuznetsov/rails_simple_auth#readme',
    'rubygems_mfa_required' => 'true'
  }

  spec.files = Dir[
    'lib/**/*',
    'app/**/*',
    'config/**/*',
    'MIT-LICENSE',
    'CHANGELOG.md',
    'README.md'
  ]

  spec.require_paths = ['lib']

  spec.add_dependency 'bcrypt', '~> 3.1'
  spec.add_dependency 'rails', '>= 8.0'

  # Optional OAuth support - users add these to their own Gemfile
  # spec.add_development_dependency "omniauth"
  # spec.add_development_dependency "omniauth-google-oauth2"
  # spec.add_development_dependency "omniauth-github"
end
