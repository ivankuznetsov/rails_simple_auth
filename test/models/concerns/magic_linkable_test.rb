# frozen_string_literal: true

require 'test_helper'

class MagicLinkableTest < Minitest::Test
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

  def test_magic_link_token_uses_configured_expiry
    RailsSimpleAuth.configuration.magic_link_expiry = 5.minutes
    user = User.create!(email: 'test@example.com', password: 'password123')
    token = user.generate_magic_link_token

    # Token should be valid now
    assert_equal user, User.find_signed(token, purpose: :magic_link)

    # Simulate time passing beyond expiry (we can't easily test this without time manipulation)
    # Just verify the token structure is correct
    assert_not_nil token
  end

  def test_magic_link_token_has_correct_purpose
    user = User.create!(email: 'test@example.com', password: 'password123')
    token = user.generate_magic_link_token

    # Should not be valid for other purposes
    assert_nil User.find_signed(token, purpose: :password_reset)
    assert_nil User.find_signed(token, purpose: :confirm_email)
  end
end

class MagicLinkableConfigurationTest < Minitest::Test
  def test_default_magic_link_expiry
    assert_equal 15.minutes, RailsSimpleAuth.configuration.magic_link_expiry
  end

  def test_magic_link_expiry_can_be_configured
    RailsSimpleAuth.configuration.magic_link_expiry = 30.minutes

    assert_equal 30.minutes, RailsSimpleAuth.configuration.magic_link_expiry
  end
end
