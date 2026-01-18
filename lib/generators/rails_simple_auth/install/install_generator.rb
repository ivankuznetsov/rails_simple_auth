# frozen_string_literal: true

require "rails/generators"
require "rails/generators/active_record"

module RailsSimpleAuth
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      source_root File.expand_path("templates", __dir__)

      class_option :user_model, type: :string, default: "User",
                   desc: "Name of your User model"
      class_option :skip_migration, type: :boolean, default: false,
                   desc: "Skip generating migration"

      def self.next_migration_number(dirname)
        ActiveRecord::Generators::Base.next_migration_number(dirname)
      end

      def create_initializer
        template "initializer.rb", "config/initializers/rails_simple_auth.rb"
      end

      def create_migration
        return if options[:skip_migration]

        migration_template "migration.rb", "db/migrate/add_rails_simple_auth.rb"
      end

      def add_routes
        route "rails_simple_auth_routes"
      end

      def show_instructions
        say ""
        say "RailsSimpleAuth installed successfully!", :green
        say ""
        say "Next steps:"
        say "  1. Review and edit the migration: db/migrate/xxx_add_rails_simple_auth.rb"
        say "  2. Run: rails db:migrate"
        say "  3. Add concerns to your #{options[:user_model]} model:"
        say ""
        say "     class #{options[:user_model]} < ApplicationRecord"
        say "       include RailsSimpleAuth::Models::Concerns::Authenticatable"
        say "       include RailsSimpleAuth::Models::Concerns::Confirmable      # optional"
        say "       include RailsSimpleAuth::Models::Concerns::MagicLinkable    # optional"
        say "       include RailsSimpleAuth::Models::Concerns::OAuthConnectable # optional"
        say "     end"
        say ""
        say "  4. Add before_action to protect routes:"
        say ""
        say "     class ApplicationController < ActionController::Base"
        say "       before_action :require_authentication"
        say "     end"
        say ""
        say "Optional generators:"
        say "  rails generate rails_simple_auth:views  # Copy views for customization"
        say "  rails generate rails_simple_auth:css    # Copy CSS for styling"
        say ""
      end
    end
  end
end
