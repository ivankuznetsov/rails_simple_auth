# frozen_string_literal: true

require 'rails/generators'
require 'rails/generators/active_record'

module RailsSimpleAuth
  module Generators
    class TemporaryUsersGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      source_root File.expand_path('templates', __dir__)

      desc 'Creates a migration to add temporary user support to your User model'

      def self.next_migration_number(dirname)
        ActiveRecord::Generators::Base.next_migration_number(dirname)
      end

      def create_migration_file
        migration_template 'add_temporary_to_users.rb.erb',
                           'db/migrate/add_temporary_to_users.rb'
      end

      def show_instructions
        say ''
        say 'Temporary users migration created!', :green
        say ''
        say 'Next steps:', :yellow
        say '  1. Run: bin/rails db:migrate'
        say ''
        say '  2. Add :temporary to your User model:'
        say '     authenticates_with :confirmable, :temporary'
        say ''
        say '  3. Enable in your initializer:'
        say '     config.temporary_users_enabled = true'
        say ''
      end
    end
  end
end
