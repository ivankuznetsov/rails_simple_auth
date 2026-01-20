# frozen_string_literal: true

module Pages
  class ConfirmationPage < BasePage
    def visit_page
      visit '/confirmations/new'
      self
    end

    def displayed?
      has_selector?('.rsa-auth-form__title', text: 'Resend Confirmation', wait: 5)
    end

    def request_confirmation(email:)
      fill_in 'Email', with: email
      click_button 'Resend Confirmation'
      self
    end

    def confirm_with_token(token:)
      visit "/confirmations/#{token}"
      self
    end

    def has_confirmation_sent_message?
      # After submission, redirects to sign in page with flash notice
      has_text?('confirmation instructions have been sent')
    end

    def has_confirmed_message?
      has_text?('Email confirmed') || has_text?('You can now sign in')
    end

    def has_invalid_token_error?
      has_text?('Invalid or expired confirmation link')
    end
  end
end
