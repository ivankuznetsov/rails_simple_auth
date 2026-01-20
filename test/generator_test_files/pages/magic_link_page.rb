# frozen_string_literal: true

module Pages
  class MagicLinkPage < BasePage
    def visit_page
      visit '/magic_link_form'
      self
    end

    def displayed?
      has_selector?('.rsa-auth-form__title', text: 'Sign In with Magic Link', wait: 5)
    end

    def request_magic_link(email:)
      fill_in 'Email', with: email
      click_button 'Send Magic Link'
      self
    end

    def has_magic_link_sent_message?
      # After submission, redirects to sign in page with flash notice
      has_text?('If an account exists') || has_text?('magic link has been sent')
    end
  end
end
