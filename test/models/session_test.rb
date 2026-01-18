# frozen_string_literal: true

require 'test_helper'

class SessionTest < Minitest::Test
  def test_belongs_to_user
    user = User.create!(email_address: 'test@example.com', password: 'password123')
    session = RailsSimpleAuth::Session.create!(user: user)

    assert_equal user, session.user
  end

  def test_recent_scope_orders_by_created_at_desc
    user = User.create!(email_address: 'test@example.com', password: 'password123')
    old_session = RailsSimpleAuth::Session.create!(user: user, created_at: 2.days.ago)
    new_session = RailsSimpleAuth::Session.create!(user: user, created_at: 1.day.ago)

    sessions = RailsSimpleAuth::Session.recent

    assert_equal new_session, sessions.first
    assert_equal old_session, sessions.last
  end

  def test_active_scope_returns_non_expired_sessions
    user = User.create!(email_address: 'test@example.com', password: 'password123')
    RailsSimpleAuth.configure { |c| c.session_expiry = 30.days }

    active = RailsSimpleAuth::Session.create!(user: user, created_at: 1.day.ago)
    RailsSimpleAuth::Session.create!(user: user, created_at: 31.days.ago)

    assert_includes RailsSimpleAuth::Session.active, active
  end

  def test_expired_scope_returns_expired_sessions
    user = User.create!(email_address: 'test@example.com', password: 'password123')
    RailsSimpleAuth.configure { |c| c.session_expiry = 30.days }

    RailsSimpleAuth::Session.create!(user: user, created_at: 1.day.ago)
    expired = RailsSimpleAuth::Session.create!(user: user, created_at: 31.days.ago)

    assert_includes RailsSimpleAuth::Session.expired, expired
  end

  def test_cleanup_expired_deletes_expired_sessions
    user = User.create!(email_address: 'test@example.com', password: 'password123')
    RailsSimpleAuth.configure { |c| c.session_expiry = 30.days }

    active = RailsSimpleAuth::Session.create!(user: user, created_at: 1.day.ago)
    RailsSimpleAuth::Session.create!(user: user, created_at: 31.days.ago)
    RailsSimpleAuth::Session.create!(user: user, created_at: 60.days.ago)

    count = RailsSimpleAuth::Session.cleanup_expired!

    assert_equal 2, count
    assert_equal [active], RailsSimpleAuth::Session.all.to_a
  end
end
