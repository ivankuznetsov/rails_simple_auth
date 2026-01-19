# frozen_string_literal: true

require 'test_helper'

class ConfigurationTest < Minitest::Test
  def setup
    @config = RailsSimpleAuth::Configuration.new
  end

  def test_default_magic_link_enabled
    assert @config.magic_link_enabled
  end

  def test_default_email_confirmation_enabled
    assert @config.email_confirmation_enabled
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
    assert_equal 'User', @config.user_class_name
  end

  def test_configure_block
    RailsSimpleAuth.configure do |config|
      config.password_minimum_length = 12
    end

    assert_equal 12, RailsSimpleAuth.configuration.password_minimum_length
  end

  def test_enable_oauth_with_symbols
    @config.enable_oauth(:google_oauth2, :github)

    assert_includes @config.oauth_providers, :google_oauth2
    assert_includes @config.oauth_providers, :github
  end

  def test_enable_oauth_with_hash
    @config.enable_oauth(google_oauth2: "Google", github: "GitHub")

    assert_includes @config.oauth_providers, :google_oauth2
    assert_includes @config.oauth_providers, :github
    assert_equal "Google", @config.oauth_provider_names[:google_oauth2]
    assert_equal "GitHub", @config.oauth_provider_names[:github]
  end

  def test_oauth_provider_display_name_with_custom_name
    @config.enable_oauth(google_oauth2: "Google", github: "GitHub")

    assert_equal "Google", @config.oauth_provider_display_name(:google_oauth2)
    assert_equal "GitHub", @config.oauth_provider_display_name(:github)
  end

  def test_oauth_provider_display_name_fallback
    @config.enable_oauth(:google_oauth2, :github)

    assert_equal "Google", @config.oauth_provider_display_name(:google_oauth2)
    assert_equal "Github", @config.oauth_provider_display_name(:github)
  end

  def test_rate_limits_defaults
    assert_equal 5, @config.rate_limits[:sign_in][:limit]
    assert_equal 15.minutes, @config.rate_limits[:sign_in][:period]
  end
end
