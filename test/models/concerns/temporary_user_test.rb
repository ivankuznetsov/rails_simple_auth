# frozen_string_literal: true

require 'test_helper'

class TemporaryUserTest < Minitest::Test
  def test_temporary_returns_true_for_temporary_user
    user = User.create!(email: 'temp@example.com', password: 'password123', temporary: true)

    assert_predicate user, :temporary?
  end

  def test_temporary_returns_false_for_permanent_user
    user = User.create!(email: 'perm@example.com', password: 'password123', temporary: false)

    assert_not user.temporary?
  end

  def test_permanent_returns_true_for_permanent_user
    user = User.create!(email: 'perm@example.com', password: 'password123', temporary: false)

    assert_predicate user, :permanent?
  end

  def test_permanent_returns_false_for_temporary_user
    user = User.create!(email: 'temp@example.com', password: 'password123', temporary: true)

    assert_not user.permanent?
  end

  def test_temporary_scope
    temp_user = User.create!(email: 'temp@example.com', password: 'password123', temporary: true)
    User.create!(email: 'perm@example.com', password: 'password123', temporary: false)

    assert_equal [temp_user], User.temporary.to_a
  end

  def test_permanent_scope
    User.create!(email: 'temp@example.com', password: 'password123', temporary: true)
    perm_user = User.create!(email: 'perm@example.com', password: 'password123', temporary: false)

    assert_equal [perm_user], User.permanent.to_a
  end

  def test_temporary_expired_scope_with_default_days
    RailsSimpleAuth.configuration.temporary_user_cleanup_days = 7

    old_user = User.create!(email: 'old@example.com', password: 'password123', temporary: true)
    old_user.update_column(:created_at, 10.days.ago) # rubocop:disable Rails/SkipsModelValidations

    recent_user = User.create!(email: 'recent@example.com', password: 'password123', temporary: true)

    assert_includes User.temporary_expired, old_user
    assert_not_includes User.temporary_expired, recent_user
  end

  def test_temporary_expired_scope_with_custom_days
    RailsSimpleAuth.configuration.temporary_user_cleanup_days = 7

    old_user = User.create!(email: 'old@example.com', password: 'password123', temporary: true)
    old_user.update_column(:created_at, 5.days.ago) # rubocop:disable Rails/SkipsModelValidations

    assert_includes User.temporary_expired(3), old_user
    assert_not_includes User.temporary_expired(7), old_user
  end

  def test_temporary_expired_only_includes_temporary_users
    RailsSimpleAuth.configuration.temporary_user_cleanup_days = 7

    old_temp = User.create!(email: 'temp@example.com', password: 'password123', temporary: true)
    old_temp.update_column(:created_at, 10.days.ago) # rubocop:disable Rails/SkipsModelValidations

    old_perm = User.create!(email: 'perm@example.com', password: 'password123', temporary: false)
    old_perm.update_column(:created_at, 10.days.ago) # rubocop:disable Rails/SkipsModelValidations

    assert_includes User.temporary_expired, old_temp
    assert_not_includes User.temporary_expired, old_perm
  end

  def test_convert_to_permanent_updates_all_fields
    user = User.create!(email: 'temp@example.com', password: 'password123', temporary: true)

    user.convert_to_permanent!(email: 'permanent@example.com', password: 'newpassword123')

    user.reload

    assert_equal 'permanent@example.com', user.email
    assert user.authenticate('newpassword123')
    assert_not user.temporary?
  end

  def test_convert_to_permanent_returns_self
    user = User.create!(email: 'temp@example.com', password: 'password123', temporary: true)

    result = user.convert_to_permanent!(email: 'permanent@example.com', password: 'newpassword123')

    assert_equal user, result
  end

  def test_convert_to_permanent_fails_when_email_taken_by_permanent_user
    User.create!(email: 'taken@example.com', password: 'password123', temporary: false)
    temp_user = User.create!(email: 'temp@example.com', password: 'password123', temporary: true)

    assert_raises(ActiveRecord::RecordInvalid) do
      temp_user.convert_to_permanent!(email: 'taken@example.com', password: 'newpassword123')
    end

    assert_predicate temp_user.errors[:email], :any?
  end

  def test_convert_to_permanent_fails_when_already_permanent
    user = User.create!(email: 'perm@example.com', password: 'password123', temporary: false)

    error = assert_raises(RailsSimpleAuth::Error) do
      user.convert_to_permanent!(email: 'new@example.com', password: 'newpassword123')
    end

    assert_match(/already permanent/, error.message)
  end

  def test_convert_to_permanent_allows_email_from_another_temporary_user
    User.create!(email: 'other_temp@example.com', password: 'password123', temporary: true)
    temp_user = User.create!(email: 'temp@example.com', password: 'password123', temporary: true)

    # Should not raise - temporary users can share emails until conversion
    temp_user.convert_to_permanent!(email: 'unique@example.com', password: 'newpassword123')

    assert_not temp_user.temporary?
  end
end

class TemporaryUserConfigurationTest < Minitest::Test
  def test_default_temporary_users_enabled
    assert_not RailsSimpleAuth.configuration.temporary_users_enabled
  end

  def test_default_temporary_user_cleanup_days
    assert_equal 7, RailsSimpleAuth.configuration.temporary_user_cleanup_days
  end

  def test_temporary_user_cleanup_days_validates_positive_integer
    assert_raises(RailsSimpleAuth::ConfigurationError) do
      RailsSimpleAuth.configuration.temporary_user_cleanup_days = 0
    end

    assert_raises(RailsSimpleAuth::ConfigurationError) do
      RailsSimpleAuth.configuration.temporary_user_cleanup_days = -1
    end

    assert_raises(RailsSimpleAuth::ConfigurationError) do
      RailsSimpleAuth.configuration.temporary_user_cleanup_days = 'invalid'
    end
  end

  def test_temporary_user_cleanup_days_accepts_positive_integer
    RailsSimpleAuth.configuration.temporary_user_cleanup_days = 14

    assert_equal 14, RailsSimpleAuth.configuration.temporary_user_cleanup_days
  end
end
