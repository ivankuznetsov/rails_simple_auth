# frozen_string_literal: true

require "test_helper"

class ConfigurationTest < Minitest::Test
  def setup
    @config = RailsSimpleAuth::Configuration.new
  end

  def test_default_magic_link_enabled
    assert_equal true, @config.magic_link_enabled
  end

  def test_default_email_confirmation_enabled
    assert_equal true, @config.email_confirmation_enabled
  end

  def test_default_password_minimum_length
    assert_equal 8, @config.password_minimum_length
  end

  def test_default_session_expiry
    assert_equal 30.days, @config.session_expiry
  end

  def test_default_magic_link_expiry
    assert_equal 15.minutes, @config.magic_link_expiry
  end

  def test_default_user_class_name
    assert_equal "User", @config.user_class_name
  end

  def test_configure_block
    RailsSimpleAuth.configure do |config|
      config.password_minimum_length = 12
    end

    assert_equal 12, RailsSimpleAuth.configuration.password_minimum_length
  end

  def test_enable_oauth
    @config.enable_oauth(:google, :github)
    assert_includes @config.oauth_providers, :google
    assert_includes @config.oauth_providers, :github
  end

  def test_rate_limits_defaults
    assert_equal 5, @config.rate_limits[:sign_in][:limit]
    assert_equal 15.minutes, @config.rate_limits[:sign_in][:period]
  end
end
