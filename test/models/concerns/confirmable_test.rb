# frozen_string_literal: true

require 'test_helper'

class ConfirmableTest < Minitest::Test
  def test_confirmed_returns_true_when_confirmed_at_is_set
    user = User.create!(email: 'test@example.com', password: 'password123', confirmed_at: Time.current)

    assert_predicate user, :confirmed?
  end

  def test_confirmed_returns_false_when_confirmed_at_is_nil
    user = User.create!(email: 'test@example.com', password: 'password123', confirmed_at: nil)

    assert_not user.confirmed?
  end

  def test_unconfirmed_returns_true_when_confirmed_at_is_nil
    user = User.create!(email: 'test@example.com', password: 'password123', confirmed_at: nil)

    assert_predicate user, :unconfirmed?
  end

  def test_unconfirmed_returns_false_when_confirmed_at_is_set
    user = User.create!(email: 'test@example.com', password: 'password123', confirmed_at: Time.current)

    assert_not user.unconfirmed?
  end

  def test_confirm_sets_confirmed_at
    user = User.create!(email: 'test@example.com', password: 'password123', confirmed_at: nil)

    assert_nil user.confirmed_at

    user.confirm!

    assert_not_nil user.confirmed_at
    assert_predicate user, :confirmed?
  end

  def test_confirm_returns_true_if_already_confirmed
    user = User.create!(email: 'test@example.com', password: 'password123', confirmed_at: Time.current)
    original_confirmed_at = user.confirmed_at

    result = user.confirm!

    assert result
    assert_equal original_confirmed_at.to_i, user.reload.confirmed_at.to_i
  end

  def test_generate_confirmation_token
    user = User.create!(email: 'test@example.com', password: 'password123')
    token = user.generate_confirmation_token

    assert_not_nil token
    assert_kind_of String, token
  end

  def test_confirmation_token_is_verifiable
    user = User.create!(email: 'test@example.com', password: 'password123')
    token = user.generate_confirmation_token
    found_user = User.find_signed(token, purpose: :email_confirmation)

    assert_equal user, found_user
  end

  def test_confirmed_scope
    confirmed = User.create!(email: 'confirmed@example.com', password: 'password123',
                             confirmed_at: Time.current)
    User.create!(email: 'unconfirmed@example.com', password: 'password123', confirmed_at: nil)

    assert_equal [confirmed], User.confirmed.to_a
  end

  def test_unconfirmed_scope
    User.create!(email: 'confirmed@example.com', password: 'password123', confirmed_at: Time.current)
    unconfirmed = User.create!(email: 'unconfirmed@example.com', password: 'password123', confirmed_at: nil)

    assert_equal [unconfirmed], User.unconfirmed.to_a
  end
end
