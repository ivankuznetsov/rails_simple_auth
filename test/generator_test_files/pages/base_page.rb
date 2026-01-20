# frozen_string_literal: true

module Pages
  class BasePage
    include Capybara::DSL
    include Capybara::Minitest::Assertions

    def initialize(test_context)
      @test_context = test_context
    end

    def has_flash_notice?(message)
      has_selector?('.rsa-flash--notice', text: message, wait: 5) ||
        has_selector?('[data-flash="notice"]', text: message, wait: 5) ||
        has_text?(message)
    end

    def has_flash_alert?(message)
      has_selector?('.rsa-flash--alert', text: message, wait: 5) ||
        has_selector?('[data-flash="alert"]', text: message, wait: 5) ||
        has_text?(message)
    end

    def current_path
      URI.parse(page.current_url).path
    end

    private

    attr_reader :test_context
  end
end
