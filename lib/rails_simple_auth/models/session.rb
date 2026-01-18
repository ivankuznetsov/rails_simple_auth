# frozen_string_literal: true

module RailsSimpleAuth
  class Session < ActiveRecord::Base
    self.table_name = "sessions"

    # Use lambda to defer class resolution until runtime
    belongs_to :user, class_name: -> { RailsSimpleAuth.configuration.user_class_name }

    validates :user_id, presence: true

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
