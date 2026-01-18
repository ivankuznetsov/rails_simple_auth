# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

# Load Rails and components before the gem since it's a Rails engine
require 'rails'
require 'active_support/all'
require 'active_record'
require 'action_controller'
require 'action_mailer'

# Set up in-memory SQLite database for testing
ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
ActiveRecord::Base.logger = Logger.new(nil)

# Define ApplicationRecord before loading the gem (required by Session model)
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end

# Create test schema
ActiveRecord::Schema.define do
  create_table :users, force: true do |t|
    t.string :email, null: false
    t.string :password_digest
    t.datetime :confirmed_at
    t.string :oauth_provider
    t.string :oauth_uid
    t.boolean :temporary, default: false, null: false
    t.timestamps
  end

  add_index :users, :email, unique: true

  create_table :sessions, force: true do |t|
    t.references :user, null: false
    t.string :ip_address
    t.string :user_agent
    t.timestamps
  end
end

# Set up a minimal Rails application for testing
module TestApp
  class Application < Rails::Application
    config.eager_load = false
    config.secret_key_base = 'test_secret_key_base_for_testing_only_minimum_128_characters_' \
                             'needed_for_proper_encryption_so_this_should_be_long_enough'
    config.hosts.clear # Allow all hosts in test
  end
end

Rails.application.initialize!

# Configure signed IDs for ActiveRecord (required for Rails 8+)
ActiveRecord::Base.signed_id_verifier_secret = Rails.application.secret_key_base

require 'rails_simple_auth'
require 'minitest/autorun'

# Define User model for testing
class User < ApplicationRecord
  include RailsSimpleAuth::Models::Concerns::Authenticatable
  include RailsSimpleAuth::Models::Concerns::Confirmable
  include RailsSimpleAuth::Models::Concerns::MagicLinkable
  include RailsSimpleAuth::Models::Concerns::TemporaryUser

  # Re-define sessions association with static class name for testing
  has_many :sessions,
           class_name: 'RailsSimpleAuth::Session',
           dependent: :destroy
end

# Monkey-patch Session for testing to use static class name
module RailsSimpleAuth
  class Session < ApplicationRecord
    self.table_name = 'sessions'
    belongs_to :user, class_name: 'User'

    scope :recent, -> { order(created_at: :desc) }
    scope :active, -> { where(created_at: RailsSimpleAuth.configuration.session_expiry.ago..) }
    scope :expired, -> { where(created_at: ...RailsSimpleAuth.configuration.session_expiry.ago) }

    def self.cleanup_expired!
      count = expired.delete_all
      Rails.logger.info("[RailsSimpleAuth] Cleaned up #{count} expired sessions")
      count
    end
  end
end

# Add Rails-style assertion helpers to Minitest
module Minitest
  class Test
    def assert_not_nil(object, message = nil)
      refute_nil(object, message)
    end

    def assert_not(object, message = nil)
      refute(object, message)
    end

    def assert_not_includes(collection, object, message = nil)
      refute_includes(collection, object, message)
    end

    def setup
      # Reset configuration before each test
      RailsSimpleAuth.reset_configuration!
    end

    def teardown
      # Clean up database after each test
      User.delete_all
      RailsSimpleAuth::Session.delete_all
    end
  end
end
