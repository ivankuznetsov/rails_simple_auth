# frozen_string_literal: true

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
  end
end
