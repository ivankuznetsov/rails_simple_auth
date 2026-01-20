# frozen_string_literal: true

module Pages
  class SignInPage < BasePage
    def visit_page
      visit '/session/new'
      self
    end

    def displayed?
      has_selector?('.rsa-auth-form__title', text: 'Sign In', wait: 5)
    end

    def sign_in(email:, password:)
      fill_in 'Email', with: email
      fill_in 'Password', with: password
      click_button 'Sign In'
      self
    end

    def click_forgot_password
      click_link 'Forgot password?'
      Pages::PasswordResetPage.new(test_context)
    end

    def click_magic_link
      click_link 'Sign in with Magic Link'
      Pages::MagicLinkPage.new(test_context)
    end

    def click_sign_up
      click_link 'Sign Up'
      Pages::SignUpPage.new(test_context)
    end

    def has_invalid_credentials_error?
      has_text?('Invalid email or password')
    end

    def has_unconfirmed_error?
      has_text?('confirm') || has_text?('Confirm')
    end
  end
end
