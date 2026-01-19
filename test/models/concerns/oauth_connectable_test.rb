# frozen_string_literal: true

require 'test_helper'

class OAuthConnectableTest < Minitest::Test
  def oauth_hash(email: 'oauth@example.com', provider: 'google', uid: '12345')
    {
      'provider' => provider,
      'uid' => uid,
      'info' => { 'email' => email }
    }
  end

  def test_from_oauth_creates_new_user
    user = User.from_oauth(oauth_hash)

    assert_not_nil user
    assert_equal 'oauth@example.com', user.email
    assert_equal 'google', user.oauth_provider
    assert_equal '12345', user.oauth_uid
    assert_predicate user, :persisted?
  end

  def test_from_oauth_auto_confirms_new_user
    user = User.from_oauth(oauth_hash)

    assert_predicate user, :confirmed?
  end

  def test_from_oauth_returns_nil_when_email_missing
    auth = oauth_hash
    auth['info'].delete('email')

    user = User.from_oauth(auth)

    assert_nil user
  end

  def test_from_oauth_returns_nil_when_email_blank
    user = User.from_oauth(oauth_hash(email: ''))

    assert_nil user
  end

  def test_from_oauth_finds_existing_user_by_oauth_credentials
    existing = User.create!(email: 'oauth@example.com', password: 'password123', oauth_provider: 'google',
                            oauth_uid: '12345')

    user = User.from_oauth(oauth_hash)

    assert_equal existing.id, user.id
  end

  def test_from_oauth_links_to_existing_email_account_when_enabled
    RailsSimpleAuth.configuration.oauth_link_existing_accounts = true
    existing = User.create!(email: 'existing@example.com', password: 'password123')

    user = User.from_oauth(oauth_hash(email: 'existing@example.com'))

    assert_equal existing.id, user.id
    assert_equal 'google', user.oauth_provider
    assert_equal '12345', user.oauth_uid
  end

  def test_from_oauth_rejects_existing_email_when_linking_disabled
    RailsSimpleAuth.configuration.oauth_link_existing_accounts = false
    User.create!(email: 'existing@example.com', password: 'password123')

    user = User.from_oauth(oauth_hash(email: 'existing@example.com'))

    assert_nil user
  end

  def test_from_oauth_returns_existing_oauth_user_even_with_different_provider_on_same_email
    existing = User.create!(email: 'shared@example.com', password: 'password123', oauth_provider: 'github',
                            oauth_uid: '99999')

    # Same email, different provider - should link if enabled
    RailsSimpleAuth.configuration.oauth_link_existing_accounts = true
    user = User.from_oauth(oauth_hash(email: 'shared@example.com', provider: 'google', uid: '12345'))

    assert_equal existing.id, user.id
    # OAuth credentials should be updated to new provider
    assert_equal 'google', user.oauth_provider
    assert_equal '12345', user.oauth_uid
  end

  def test_from_oauth_finds_by_oauth_credentials_first
    # Create user with different email but same oauth credentials
    existing = User.create!(email: 'original@example.com', password: 'password123', oauth_provider: 'google',
                            oauth_uid: '12345')

    # OAuth with different email but same provider+uid should find existing user
    user = User.from_oauth(oauth_hash(email: 'different@example.com'))

    assert_equal existing.id, user.id
    # Email should NOT change when found by oauth credentials
    assert_equal 'original@example.com', user.email
  end

  def test_assign_oauth_attributes_is_called_on_new_user
    user = User.from_oauth(oauth_hash(provider: 'github', uid: 'abc123'))

    assert_equal 'github', user.oauth_provider
    assert_equal 'abc123', user.oauth_uid
  end

  def test_assign_oauth_attributes_is_called_when_linking_existing_account
    RailsSimpleAuth.configuration.oauth_link_existing_accounts = true
    existing = User.create!(email: 'test@example.com', password: 'password123')

    assert_nil existing.oauth_provider

    User.from_oauth(oauth_hash(email: 'test@example.com', provider: 'github', uid: 'abc123'))

    existing.reload

    assert_equal 'github', existing.oauth_provider
    assert_equal 'abc123', existing.oauth_uid
  end
end

class OAuthConnectableConfigurationTest < Minitest::Test
  def test_default_oauth_link_existing_accounts_is_true
    assert RailsSimpleAuth.configuration.oauth_link_existing_accounts
  end

  def test_oauth_link_existing_accounts_can_be_disabled
    RailsSimpleAuth.configuration.oauth_link_existing_accounts = false

    assert_not RailsSimpleAuth.configuration.oauth_link_existing_accounts
  end
end
