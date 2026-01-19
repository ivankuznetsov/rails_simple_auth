# frozen_string_literal: true

require 'rails_simple_auth/model'

module RailsSimpleAuth
  class Engine < ::Rails::Engine
    isolate_namespace RailsSimpleAuth

    config.generators do |g|
      g.test_framework :minitest
    end

    initializer 'rails_simple_auth.helpers' do
      ActiveSupport.on_load(:action_controller_base) do
        include RailsSimpleAuth::Controllers::Concerns::Authentication
        include RailsSimpleAuth::Controllers::Concerns::SessionManagement
      end
    end

    initializer 'rails_simple_auth.model' do
      ActiveSupport.on_load(:active_record) do
        include RailsSimpleAuth::Model
      end
    end

    # Secure OmniAuth by default - only allow POST to initiate OAuth (prevents CSRF)
    # Disable OmniAuth's authenticity token protection since POST-only already prevents CSRF
    # and Rails handles CSRF protection at the application level
    initializer 'rails_simple_auth.omniauth', after: :load_config_initializers do
      if defined?(OmniAuth)
        OmniAuth.config.allowed_request_methods = %i[post]
        OmniAuth.config.request_validation_phase = nil
      end
    end
  end
end
