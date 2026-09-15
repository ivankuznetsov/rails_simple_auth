# frozen_string_literal: true

require 'test_helper'
require 'action_controller/test_case'

AUTH_TEST_ROUTES = ActionDispatch::Routing::RouteSet.new
AUTH_TEST_ROUTES.draw { rails_simple_auth_routes }

class ApplicationController < ActionController::Base
  include AUTH_TEST_ROUTES.url_helpers

  helper_method :main_app

  def main_app
    _routes.url_helpers
  end
end

require_relative '../../app/controllers/rails_simple_auth/base_controller'
require_relative '../../app/controllers/rails_simple_auth/sessions_controller'
require_relative '../../app/controllers/rails_simple_auth/confirmations_controller'

# The gem test app has no host middleware stack; exercise the real actions and views directly.
class SessionsControllerTest < ActionController::TestCase # rubocop:disable Rails/ActionControllerTestCase
  tests RailsSimpleAuth::SessionsController

  def setup
    super
    RailsSimpleAuth.reset_configuration!
    RailsSimpleAuth.configuration.layout = false
    RailsSimpleAuth::Current.reset
    @previous_queue_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test
    @routes = AUTH_TEST_ROUTES
    @controller.prepend_view_path File.expand_path('../../app/views', __dir__)
    @user = User.create!(email: 'unconfirmed@example.com', password: 'password123')
  end

  def teardown
    ActiveJob::Base.queue_adapter = @previous_queue_adapter
    RailsSimpleAuth::Current.reset
    RailsSimpleAuth::Session.delete_all
    User.delete_all
    super
  end

  def test_unconfirmed_login_redirects_to_confirmation_with_email
    post :create, params: { email: @user.email, password: 'password123' }, session: { return_to: '/checkout' }

    assert_redirected_to '/confirmations/new'
    assert_equal @user.email, session[:confirmation_email]
    assert_equal '/checkout', session[:return_to]
  end

  def test_unconfirmed_login_does_not_sign_in_or_send_mail
    assert_no_difference ['RailsSimpleAuth::Session.count', 'ActiveJob::Base.queue_adapter.enqueued_jobs.size'] do
      post :create, params: { email: @user.email, password: 'password123' }
    end

    assert_nil cookies[:session_token]
    assert_nil RailsSimpleAuth::Current.user
  end

  def test_incorrect_password_keeps_login_error
    post :create, params: { email: @user.email, password: 'incorrect' }

    assert_response :unprocessable_content
    assert_nil session[:confirmation_email]
    assert_equal 0, RailsSimpleAuth::Session.count
  end

  def test_confirmed_user_signs_in
    @user.confirm!

    post :create, params: { email: @user.email, password: 'password123' }, session: { return_to: '/checkout' }

    assert_redirected_to '/checkout'
    assert_equal @user, RailsSimpleAuth::Current.user
    assert_equal 1, @user.sessions.count
  end

  def test_confirmation_disabled_user_signs_in
    RailsSimpleAuth.configuration.email_confirmation_enabled = false

    post :create, params: { email: @user.email, password: 'password123' }, session: { return_to: '/checkout' }

    assert_redirected_to '/checkout'
    assert_equal @user, RailsSimpleAuth::Current.user
    assert_equal 1, @user.sessions.count
  end

  def test_confirmation_form_prefills_remembered_email
    @controller = RailsSimpleAuth::ConfirmationsController.new
    @controller.prepend_view_path File.expand_path('../../app/views', __dir__)

    get :new, session: { confirmation_email: @user.email }

    assert_response :success
    assert_select 'input[type=email][value=?]', @user.email
  end
end
