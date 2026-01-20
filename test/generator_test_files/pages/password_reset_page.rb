# frozen_string_literal: true

module Pages
  class PasswordResetPage < BasePage
    def visit_page
      visit '/passwords/new'
      self
    end

    def displayed?
      has_selector?('.rsa-auth-form__title', text: 'Reset Password', wait: 5)
    end

    def request_reset(email:)
      fill_in 'Email', with: email
      click_button 'Send Reset Instructions'
      self
    end

    def has_reset_email_sent_message?
      # After submission, redirects to sign in page with flash notice
      has_text?('If an account exists') || has_text?('instructions have been sent')
    end
  end

  class PasswordEditPage < BasePage
    def visit_page(token:)
      visit "/passwords/#{token}/edit"
      self
    end

    def displayed?
      has_selector?('.rsa-auth-form__title', text: 'Set New Password', wait: 5)
    end

    def reset_password(password:, password_confirmation: nil)
      fill_in 'New Password', with: password
      fill_in 'Confirm Password', with: password_confirmation || password
      click_button 'Update Password'
      self
    end

    def has_invalid_token_error?
      has_text?('Invalid or expired password reset link')
    end
  end
end
