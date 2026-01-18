# frozen_string_literal: true

require "rails_simple_auth/version"
require "rails_simple_auth/configuration"
require "rails_simple_auth/engine"

# Model concerns
require "rails_simple_auth/models/concerns/authenticatable"
require "rails_simple_auth/models/concerns/confirmable"
require "rails_simple_auth/models/concerns/magic_linkable"
require "rails_simple_auth/models/concerns/oauth_connectable"
require "rails_simple_auth/models/current"
require "rails_simple_auth/models/session"

# Controller concerns
require "rails_simple_auth/controllers/concerns/authentication"
require "rails_simple_auth/controllers/concerns/session_management"

# Routes
require "rails_simple_auth/routes"

module RailsSimpleAuth
  class Error < StandardError; end
  class ConfigurationError < Error; end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end
