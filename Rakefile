# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  # Exclude generator_test_files - those are template tests for generated apps
  t.test_files = FileList['test/**/*_test.rb'].exclude('test/generator_test_files/**/*')
end

task default: :test
