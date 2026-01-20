# frozen_string_literal: true

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test 'user has authenticates_with modules included' do
    user = User.new

    assert_respond_to user, :authenticate, 'User should respond to authenticate'
    assert_respond_to user, :confirmed?, 'User should respond to confirmed?'
    assert_respond_to user, :generate_magic_link_token, 'User should respond to generate_magic_link_token'
  end

  test 'user can be created with valid attributes' do
    user = User.new(
      email: 'valid@example.com',
      password: 'password123',
      password_confirmation: 'password123'
    )

    assert_predicate user, :valid?, "User should be valid: #{user.errors.full_messages.join(', ')}"
  end

  test 'user requires email' do
    user = User.new(
      password: 'password123',
      password_confirmation: 'password123'
    )

    assert_not user.valid?, 'User should not be valid without email'
    assert_includes user.errors[:email], "can't be blank"
  end

  test 'user requires password' do
    user = User.new(email: 'test@example.com')

    assert_not user.valid?, 'User should not be valid without password'
    assert_predicate user.errors[:password], :any?, 'Should have password error'
  end

  test 'user email must be unique' do
    User.create!(
      email: 'duplicate@example.com',
      password: 'password123',
      password_confirmation: 'password123',
      confirmed_at: Time.current
    )

    user = User.new(
      email: 'duplicate@example.com',
      password: 'password123',
      password_confirmation: 'password123'
    )

    assert_not user.valid?, 'User should not be valid with duplicate email'
    assert_includes user.errors[:email], 'has already been taken'
  end

  test 'user password must meet minimum length' do
    user = User.new(
      email: 'short@example.com',
      password: 'short',
      password_confirmation: 'short'
    )

    assert_not user.valid?, 'User should not be valid with short password'
    assert user.errors[:password].any? { |e| e.include?('at least') },
           'Should have password length error'
  end

  test 'user can authenticate with correct password' do
    user = User.create!(
      email: 'auth@example.com',
      password: 'password123',
      password_confirmation: 'password123',
      confirmed_at: Time.current
    )

    assert user.authenticate('password123'), 'Should authenticate with correct password'
  end

  test 'user cannot authenticate with incorrect password' do
    user = User.create!(
      email: 'auth_fail@example.com',
      password: 'password123',
      password_confirmation: 'password123',
      confirmed_at: Time.current
    )

    assert_not user.authenticate('wrongpassword'), 'Should not authenticate with wrong password'
  end

  test 'user confirmed? returns true when confirmed_at is set' do
    user = User.new(confirmed_at: Time.current)

    assert_predicate user, :confirmed?, 'User should be confirmed when confirmed_at is set'
  end

  test 'user confirmed? returns false when confirmed_at is nil' do
    user = User.new(confirmed_at: nil)

    assert_not user.confirmed?, 'User should not be confirmed when confirmed_at is nil'
  end

  test 'user can generate magic link token' do
    user = User.create!(
      email: 'magic@example.com',
      password: 'password123',
      password_confirmation: 'password123',
      confirmed_at: Time.current
    )

    token = user.generate_magic_link_token

    assert_predicate token, :present?, 'Should generate magic link token'
    assert_kind_of String, token
  end

  test 'user can generate password reset token' do
    user = User.create!(
      email: 'reset@example.com',
      password: 'password123',
      password_confirmation: 'password123',
      confirmed_at: Time.current
    )

    token = user.generate_password_reset_token

    assert_predicate token, :present?, 'Should generate password reset token'
    assert_kind_of String, token
  end

  test 'user can generate confirmation token' do
    user = User.create!(
      email: 'confirm_token@example.com',
      password: 'password123',
      password_confirmation: 'password123'
    )

    token = user.generate_confirmation_token

    assert_predicate token, :present?, 'Should generate confirmation token'
    assert_kind_of String, token
  end
end
