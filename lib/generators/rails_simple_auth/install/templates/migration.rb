# frozen_string_literal: true

class AddRailsSimpleAuth < ActiveRecord::Migration[8.0]
  def change
    # ============================================================================
    # User fields (add to your existing users table)
    # ============================================================================
    #
    # If you're creating a new users table, use create_table instead of add_column
    #
    # Uncomment and modify as needed:

    # Required fields for authentication
    # add_column :users, :email, :string, null: false
    # add_column :users, :password_digest, :string, null: false

    # Email confirmation (optional - if using Confirmable concern)
    # add_column :users, :confirmed_at, :datetime

    # Add your custom fields here:
    # add_column :users, :name, :string
    # add_column :users, :admin, :boolean, default: false

    # Indexes
    # add_index :users, :email, unique: true
    # add_index :users, :confirmed_at

    # ============================================================================
    # Sessions table (required)
    # ============================================================================

    create_table :sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :ip_address
      t.string :user_agent

      t.timestamps
    end

    add_index :sessions, :created_at
  end
end
