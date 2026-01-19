# frozen_string_literal: true

require 'test_helper'

class ModelTest < Minitest::Test
  def setup
    # Ensure the Model module is included in ActiveRecord::Base for dynamic class creation
    ActiveRecord::Base.include(RailsSimpleAuth::Model) unless ActiveRecord::Base.respond_to?(:authenticates_with)
  end

  def test_authenticates_with_includes_base_module
    klass = Class.new(ActiveRecord::Base) do
      self.table_name = 'users'
      authenticates_with
    end

    assert klass.include?(RailsSimpleAuth::Models::Concerns::Authenticatable)
  end

  def test_authenticates_with_includes_confirmable
    klass = Class.new(ActiveRecord::Base) do
      self.table_name = 'users'
      authenticates_with :confirmable
    end

    assert klass.include?(RailsSimpleAuth::Models::Concerns::Authenticatable)
    assert klass.include?(RailsSimpleAuth::Models::Concerns::Confirmable)
  end

  def test_authenticates_with_includes_multiple_modules
    klass = Class.new(ActiveRecord::Base) do
      self.table_name = 'users'
      authenticates_with :confirmable, :magic_linkable, :temporary
    end

    assert klass.include?(RailsSimpleAuth::Models::Concerns::Authenticatable)
    assert klass.include?(RailsSimpleAuth::Models::Concerns::Confirmable)
    assert klass.include?(RailsSimpleAuth::Models::Concerns::MagicLinkable)
    assert klass.include?(RailsSimpleAuth::Models::Concerns::TemporaryUser)
  end

  def test_authenticates_with_includes_oauth
    klass = Class.new(ActiveRecord::Base) do
      self.table_name = 'users'
      authenticates_with :oauth
    end

    assert klass.include?(RailsSimpleAuth::Models::Concerns::OAuthConnectable)
  end

  def test_authenticates_with_raises_on_unknown_module
    assert_raises(ArgumentError) do
      Class.new(ActiveRecord::Base) do
        self.table_name = 'users'
        authenticates_with :unknown_module
      end
    end
  end

  def test_authenticates_with_error_message_lists_available_modules
    error = assert_raises(ArgumentError) do
      Class.new(ActiveRecord::Base) do
        self.table_name = 'users'
        authenticates_with :invalid
      end
    end

    assert_includes error.message, 'confirmable'
    assert_includes error.message, 'magic_linkable'
    assert_includes error.message, 'oauth'
    assert_includes error.message, 'temporary'
  end
end
