# frozen_string_literal: true

module RailsSimpleAuth
  class BaseController < ::ApplicationController
    include RailsSimpleAuth::Controllers::Concerns::Authentication
    include RailsSimpleAuth::Controllers::Concerns::SessionManagement

    layout -> { RailsSimpleAuth.configuration.layout }

    private

    def user_class
      RailsSimpleAuth.configuration.user_class
    end
  end
end
