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
    found_user = User.find_signed(token, purpose: :confirm_email)

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

  def test_reconfirming_returns_true_when_unconfirmed_email_present
    user = User.create!(email: 'test@example.com', password: 'password123', confirmed_at: Time.current)
    user.update_column(:unconfirmed_email, 'new@example.com') # rubocop:disable Rails/SkipsModelValidations

    assert_predicate user, :reconfirming?
  end

  def test_reconfirming_returns_false_when_unconfirmed_email_blank
    user = User.create!(email: 'test@example.com', password: 'password123', confirmed_at: Time.current)

    assert_not user.reconfirming?
  end

  def test_unconfirmed_or_reconfirming_returns_true_when_unconfirmed
    user = User.create!(email: 'test@example.com', password: 'password123', confirmed_at: nil)

    assert_predicate user, :unconfirmed_or_reconfirming?
  end

  def test_unconfirmed_or_reconfirming_returns_true_when_reconfirming
    user = User.create!(email: 'test@example.com', password: 'password123', confirmed_at: Time.current)
    user.update_column(:unconfirmed_email, 'new@example.com') # rubocop:disable Rails/SkipsModelValidations

    assert_predicate user, :unconfirmed_or_reconfirming?
  end

  def test_unconfirmed_or_reconfirming_returns_false_when_confirmed_and_not_reconfirming
    user = User.create!(email: 'test@example.com', password: 'password123', confirmed_at: Time.current)

    assert_not user.unconfirmed_or_reconfirming?
  end

  def test_confirmable_email_returns_email_when_not_reconfirming
    user = User.create!(email: 'test@example.com', password: 'password123')

    assert_equal 'test@example.com', user.confirmable_email
  end

  def test_confirmable_email_returns_unconfirmed_email_when_reconfirming
    user = User.create!(email: 'test@example.com', password: 'password123', confirmed_at: Time.current)
    user.update_column(:unconfirmed_email, 'new@example.com') # rubocop:disable Rails/SkipsModelValidations

    assert_equal 'new@example.com', user.confirmable_email
  end

  def test_confirm_handles_reconfirmation
    user = User.create!(email: 'test@example.com', password: 'password123', confirmed_at: Time.current)
    user.update_column(:unconfirmed_email, 'new@example.com') # rubocop:disable Rails/SkipsModelValidations

    result = user.confirm!

    assert result
    assert_equal 'new@example.com', user.reload.email
    assert_nil user.unconfirmed_email
  end

  def test_confirm_fails_when_reconfirming_email_is_taken
    User.create!(email: 'taken@example.com', password: 'password123')
    user = User.create!(email: 'test@example.com', password: 'password123', confirmed_at: Time.current)
    user.update_column(:unconfirmed_email, 'taken@example.com') # rubocop:disable Rails/SkipsModelValidations

    result = user.confirm!

    assert_not result
    assert_predicate user.errors[:email], :any?
    assert_equal 'test@example.com', user.reload.email
    assert_equal 'taken@example.com', user.unconfirmed_email
  end

  def test_confirm_sets_temporary_to_false_when_column_exists
    user = User.create!(email: 'test@example.com', password: 'password123', confirmed_at: nil, temporary: true)

    assert_predicate user, :temporary?

    user.confirm!

    assert_not user.reload.temporary?
  end
end
