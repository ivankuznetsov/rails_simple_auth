# frozen_string_literal: true

module RailsSimpleAuth
  class Current < ActiveSupport::CurrentAttributes
    attribute :user, :session
  end
end
