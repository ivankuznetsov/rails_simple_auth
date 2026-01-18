# frozen_string_literal: true

require 'test_helper'

class AuthenticatableTest < Minitest::Test
  def test_validates_email_presence
    user = User.new(password: 'password123')

    assert_predicate user, :invalid?
    assert_includes user.errors[:email], "can't be blank"
  end

  def test_validates_email_format
    user = User.new(email: 'invalid-email', password: 'password123')

    assert_predicate user, :invalid?
    assert_includes user.errors[:email], 'is invalid'
  end

  def test_validates_email_uniqueness
    User.create!(email: 'test@example.com', password: 'password123')
    duplicate = User.new(email: 'test@example.com', password: 'password456')

    assert_predicate duplicate, :invalid?
    assert_includes duplicate.errors[:email], 'has already been taken'
  end

  def test_email_uniqueness_is_case_insensitive
    User.create!(email: 'test@example.com', password: 'password123')
    duplicate = User.new(email: 'TEST@EXAMPLE.COM', password: 'password456')

    assert_predicate duplicate, :invalid?
    assert_includes duplicate.errors[:email], 'has already been taken'
  end

  def test_normalizes_email
    user = User.new(email: '  TEST@EXAMPLE.COM  ', password: 'password123')

    assert_equal 'test@example.com', user.email
  end

  def test_validates_password_minimum_length
    RailsSimpleAuth.configure { |c| c.password_minimum_length = 10 }
    user = User.new(email: 'test@example.com', password: 'short')

    assert_predicate user, :invalid?
    assert_includes user.errors[:password], 'must be at least 10 characters'
  end

  def test_password_validation_uses_configured_length
    RailsSimpleAuth.configure { |c| c.password_minimum_length = 12 }
    user = User.new(email: 'test@example.com', password: '12345678901')

    assert_predicate user, :invalid?
    assert_includes user.errors[:password], 'must be at least 12 characters'

    user.password = '123456789012'

    assert_predicate user, :valid?
  end

  def test_has_secure_password
    user = User.create!(email: 'test@example.com', password: 'password123')

    assert user.authenticate('password123')
    assert_not user.authenticate('wrong_password')
  end

  def test_find_by_email_with_valid_email
    created_user = User.create!(email: 'test@example.com', password: 'password123')
    found_user = User.find_by_email('test@example.com')

    assert_equal created_user, found_user
  end

  def test_find_by_email_is_case_insensitive
    created_user = User.create!(email: 'test@example.com', password: 'password123')
    found_user = User.find_by_email('TEST@EXAMPLE.COM')

    assert_equal created_user, found_user
  end

  def test_find_by_email_strips_whitespace
    created_user = User.create!(email: 'test@example.com', password: 'password123')
    found_user = User.find_by_email('  test@example.com  ')

    assert_equal created_user, found_user
  end

  def test_find_by_email_returns_nil_for_blank_email
    assert_nil User.find_by_email(nil)
    assert_nil User.find_by_email('')
    assert_nil User.find_by_email('   ')
  end

  def test_find_by_email_returns_nil_for_nonexistent_user
    assert_nil User.find_by_email('nonexistent@example.com')
  end

  def test_generate_password_reset_token
    user = User.create!(email: 'test@example.com', password: 'password123')
    token = user.generate_password_reset_token

    assert_not_nil token
    assert_kind_of String, token
  end

  def test_password_reset_token_is_verifiable
    user = User.create!(email: 'test@example.com', password: 'password123')
    token = user.generate_password_reset_token
    found_user = User.find_signed(token, purpose: :password_reset)

    assert_equal user, found_user
  end

  def test_generate_magic_link_token
    user = User.create!(email: 'test@example.com', password: 'password123')
    token = user.generate_magic_link_token

    assert_not_nil token
    assert_kind_of String, token
  end

  def test_magic_link_token_is_verifiable
    user = User.create!(email: 'test@example.com', password: 'password123')
    token = user.generate_magic_link_token
    found_user = User.find_signed(token, purpose: :magic_link)

    assert_equal user, found_user
  end

  def test_has_many_sessions
    user = User.create!(email: 'test@example.com', password: 'password123')

    assert_respond_to user, :sessions
    assert_equal 0, user.sessions.count
  end

  def test_sessions_are_destroyed_with_user
    user = User.create!(email: 'test@example.com', password: 'password123')
    RailsSimpleAuth::Session.create!(user: user)
    RailsSimpleAuth::Session.create!(user: user)

    assert_equal 2, RailsSimpleAuth::Session.count

    user.destroy

    assert_equal 0, RailsSimpleAuth::Session.count
  end

  def test_invalidate_all_sessions
    user = User.create!(email: 'test@example.com', password: 'password123')
    RailsSimpleAuth::Session.create!(user: user)
    RailsSimpleAuth::Session.create!(user: user)
    RailsSimpleAuth::Session.create!(user: user)

    count = user.invalidate_all_sessions!

    assert_equal 3, count
    assert_equal 0, user.sessions.count
  end
end
