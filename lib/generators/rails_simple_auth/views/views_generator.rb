# frozen_string_literal: true

require 'rails/generators'

module RailsSimpleAuth
  module Generators
    class ViewsGenerator < Rails::Generators::Base
      source_root File.expand_path('../../../../app/views/rails_simple_auth', __dir__)

      class_option :only, type: :array, default: [],
                          desc: 'Only copy specific view directories (sessions, registrations, passwords, confirmations, mailers)'

      def copy_views
        view_directories.each do |dir|
          directory dir, "app/views/rails_simple_auth/#{dir}"
        end

        say ''
        say 'Views copied to app/views/rails_simple_auth/', :green
        say ''
        say 'You can now customize these views. Rails will use your local copies'
        say "instead of the gem's views."
        say ''
      end

      private

      def view_directories
        all_dirs = %w[sessions registrations passwords confirmations mailers]

        if options[:only].any?
          all_dirs & options[:only]
        else
          all_dirs
        end
      end
    end
  end
end
