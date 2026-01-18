# frozen_string_literal: true

module RailsSimpleAuth
  module Routes
    def rails_simple_auth_routes(options = {})
      controllers = {
        sessions: options.fetch(:sessions_controller, "rails_simple_auth/sessions"),
        registrations: options.fetch(:registrations_controller, "rails_simple_auth/registrations"),
        passwords: options.fetch(:passwords_controller, "rails_simple_auth/passwords"),
        confirmations: options.fetch(:confirmations_controller, "rails_simple_auth/confirmations"),
        omniauth: options.fetch(:omniauth_controller, "rails_simple_auth/omniauth_callbacks")
      }

      config = RailsSimpleAuth.configuration

      # Core authentication routes (always registered)
      resource :session, only: %i[new create destroy], controller: controllers[:sessions]

      get "sign_up", to: "#{controllers[:registrations]}#new", as: :sign_up
      post "sign_up", to: "#{controllers[:registrations]}#create"

      resources :passwords, param: :token, only: %i[new create edit update], controller: controllers[:passwords]

      # Email confirmation routes (only when enabled)
      if config.email_confirmation_enabled
        resources :confirmations, only: %i[new create], controller: controllers[:confirmations]
        get "confirmations/:token", to: "#{controllers[:confirmations]}#show", as: :confirmation
      end

      # Magic link routes (only when enabled)
      if config.magic_link_enabled
        get "magic_link_form", to: "#{controllers[:sessions]}#magic_link_form", as: :magic_link_form
        post "request_magic_link", to: "#{controllers[:sessions]}#request_magic_link", as: :request_magic_link
        get "magic_link", to: "#{controllers[:sessions]}#magic_link_login", as: :magic_link
      end

      # OAuth routes (only when enabled)
      if config.oauth_enabled
        get "/auth/:provider/callback", to: "#{controllers[:omniauth]}#create", as: :omniauth_callback
        get "/auth/failure", to: "#{controllers[:omniauth]}#failure", as: :omniauth_failure
      end
    end
  end
end

ActionDispatch::Routing::Mapper.include(RailsSimpleAuth::Routes)
