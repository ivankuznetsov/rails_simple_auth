# frozen_string_literal: true

require 'test_helper'

# Mock controller for testing Authentication concern
class MockController
  # Mock Rails controller class methods
  def self.before_action(*_args); end

  def self.helper_method(*_args); end

  include RailsSimpleAuth::Controllers::Concerns::Authentication

  attr_accessor :cookies, :session, :request

  def initialize
    @cookies = MockCookies.new
    @session = {}
    @request = MockRequest.new
  end

  # Simulate root_path helper
  def root_path
    '/'
  end

  # Simulate new_session_path helper
  def new_session_path
    '/sign_in'
  end

  # Make private methods accessible for testing
  public :set_current_user, :store_location_for_redirect, :stored_location_or_default,
         :client_ip, :resolve_path, :current_user, :user_signed_in?
end

class MockCookies
  def initialize
    @store = {}
    @signed = MockSignedCookies.new(@store)
  end

  attr_reader :signed

  delegate :delete, to: :@store

  delegate :[], to: :@store

  delegate :[]=, to: :@store
end

class MockSignedCookies
  def initialize(store)
    @store = store
  end

  def permanent
    self
  end

  delegate :[], to: :@store

  delegate :[]=, to: :@store
end

class MockRequest
  attr_accessor :fullpath, :remote_ip, :headers

  def initialize
    @fullpath = '/dashboard'
    @remote_ip = '127.0.0.1'
    @headers = {}
  end

  def get?
    true
  end
end

class AuthenticationConcernTest < Minitest::Test
  def setup
    super
    # Reset the Current state between tests
    RailsSimpleAuth::Current.reset
    @controller = MockController.new
  end

  def test_current_user_returns_nil_when_not_signed_in
    assert_nil @controller.current_user
  end

  def test_user_signed_in_returns_false_when_not_signed_in
    assert_not @controller.user_signed_in?
  end

  def test_current_user_returns_user_when_signed_in
    user = User.create!(email: 'test@example.com', password: 'password123')
    session = RailsSimpleAuth::Session.create!(user: user)
    @controller.cookies.signed.permanent[:session_token] = session.id

    @controller.set_current_user

    assert_equal user, @controller.current_user
  end

  def test_user_signed_in_returns_true_when_signed_in
    user = User.create!(email: 'test@example.com', password: 'password123')
    session = RailsSimpleAuth::Session.create!(user: user)
    @controller.cookies.signed.permanent[:session_token] = session.id

    @controller.set_current_user

    assert_predicate @controller, :user_signed_in?
  end

  def test_set_current_user_clears_cookie_when_session_not_found
    @controller.cookies.signed.permanent[:session_token] = 999_999

    @controller.set_current_user

    assert_nil @controller.cookies[:session_token]
  end

  def test_store_location_stores_path_for_get_requests
    @controller.request.fullpath = '/protected/resource'

    @controller.store_location_for_redirect

    assert_equal '/protected/resource', @controller.session[:return_to]
  end

  def test_store_location_rejects_protocol_relative_urls
    @controller.request.fullpath = '//evil.com/attack'

    @controller.store_location_for_redirect

    assert_nil @controller.session[:return_to]
  end

  def test_store_location_rejects_non_relative_paths
    # Mock a non-relative path (shouldn't happen in practice but test defense)
    @controller.request.fullpath = 'http://evil.com'

    @controller.store_location_for_redirect

    assert_nil @controller.session[:return_to]
  end

  def test_stored_location_or_default_returns_stored_location
    @controller.session[:return_to] = '/protected/resource'

    result = @controller.stored_location_or_default

    assert_equal '/protected/resource', result
    assert_nil @controller.session[:return_to]
  end

  def test_stored_location_or_default_returns_configured_path_when_no_stored_location
    RailsSimpleAuth.configuration.after_sign_in_path = '/dashboard'

    result = @controller.stored_location_or_default

    assert_equal '/dashboard', result
  end

  def test_client_ip_prefers_cloudflare_header
    @controller.request.headers['CF-Connecting-IP'] = '1.2.3.4'
    @controller.request.headers['X-Forwarded-For'] = '5.6.7.8, 9.10.11.12'
    @controller.request.remote_ip = '127.0.0.1'

    assert_equal '1.2.3.4', @controller.client_ip
  end

  def test_client_ip_uses_x_forwarded_for_when_no_cloudflare
    @controller.request.headers['X-Forwarded-For'] = '5.6.7.8, 9.10.11.12'
    @controller.request.remote_ip = '127.0.0.1'

    assert_equal '5.6.7.8', @controller.client_ip
  end

  def test_client_ip_uses_remote_ip_as_fallback
    @controller.request.remote_ip = '127.0.0.1'

    assert_equal '127.0.0.1', @controller.client_ip
  end

  def test_resolve_path_with_string
    RailsSimpleAuth.configuration.after_sign_in_path = '/custom/path'

    result = @controller.resolve_path(:after_sign_in_path)

    assert_equal '/custom/path', result
  end

  def test_resolve_path_with_symbol
    RailsSimpleAuth.configuration.after_sign_in_path = :root_path

    result = @controller.resolve_path(:after_sign_in_path)

    assert_equal '/', result
  end

  def test_resolve_path_with_proc
    RailsSimpleAuth.configuration.after_sign_in_path = ->(_controller) { '/dynamic/path' }

    result = @controller.resolve_path(:after_sign_in_path)

    assert_equal '/dynamic/path', result
  end

  def test_resolve_path_falls_back_to_root_for_invalid_config
    RailsSimpleAuth.configuration.after_sign_in_path = 123

    result = @controller.resolve_path(:after_sign_in_path)

    assert_equal '/', result
  end
end
