# frozen_string_literal: true

module Pages
  class DashboardPage < BasePage
    def visit_page
      visit '/dashboard'
      self
    end

    def displayed?
      has_selector?('.rsa-auth-form__title', text: 'Dashboard', wait: 5)
    end

    def has_welcome_message_for?(email)
      has_text?(email)
    end

    def sign_out
      click_button 'Sign Out'
      Pages::SignInPage.new(test_context)
    end
  end
end
