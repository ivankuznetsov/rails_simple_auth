# frozen_string_literal: true

module Pages
  class LandingPage < BasePage
    def visit_page
      visit '/'
      self
    end

    def displayed?
      has_selector?('.rsa-auth-form__title', text: 'rails_simple_auth Demo', wait: 5)
    end

    def click_sign_in
      click_link 'Sign In'
      Pages::SignInPage.new(test_context)
    end

    def click_sign_up
      click_link 'Sign Up'
      Pages::SignUpPage.new(test_context)
    end
  end
end
