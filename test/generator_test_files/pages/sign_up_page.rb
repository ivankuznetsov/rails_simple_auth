# frozen_string_literal: true

module Pages
  class SignUpPage < BasePage
    def visit_page
      visit '/sign_up'
      self
    end

    def displayed?
      has_selector?('.rsa-auth-form__title', text: 'Sign Up', wait: 5)
    end

    def sign_up(email:, password:)
      fill_in 'Email', with: email
      fill_in 'Password', with: password
      click_button 'Sign Up'
      self
    end

    def click_sign_in
      click_link 'Already have an account? Sign In'
      Pages::SignInPage.new(test_context)
    end

    def has_email_taken_error?
      has_text?('has already been taken') || has_text?('Email has already been taken')
    end

    def has_password_too_short_error?
      has_text?('at least') || has_text?('must be at least')
    end
  end
end
