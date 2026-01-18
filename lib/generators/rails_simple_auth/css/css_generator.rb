# frozen_string_literal: true

require 'rails/generators'

module RailsSimpleAuth
  module Generators
    class CssGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)

      class_option :path, type: :string, default: 'app/assets/stylesheets',
                          desc: 'Path to copy CSS to'

      def copy_css
        template 'rails_simple_auth.css', "#{options[:path]}/rails_simple_auth.css"

        say ''
        say "CSS copied to #{options[:path]}/rails_simple_auth.css", :green
        say ''
        say 'To use this CSS:'
        say ''
        say '  1. Include in your application.css or layout:'
        say "     <%= stylesheet_link_tag 'rails_simple_auth' %>"
        say ''
        say '  2. Customize by overriding CSS variables in your own stylesheet:'
        say ''
        say '     :root {'
        say '       --rsa-color-primary: #your-brand-color;'
        say '       --rsa-color-background-form: #your-form-bg;'
        say '     }'
        say ''
        say '  3. Or edit rails_simple_auth.css directly.'
        say ''
      end
    end
  end
end
