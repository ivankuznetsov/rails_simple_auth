# frozen_string_literal: true

require 'test_helper'

class VersionTest < Minitest::Test
  def test_version_exists
    assert_not_nil RailsSimpleAuth::VERSION
  end

  def test_version_format
    assert_match(/\A\d+\.\d+\.\d+\z/, RailsSimpleAuth::VERSION)
  end
end
