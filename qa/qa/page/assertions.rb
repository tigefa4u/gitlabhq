# frozen_string_literal: true

require 'capybara/dsl'

module QA
  module Page
    module Assertions
      include Capybara::DSL

      def assert_no_content(text)
        assert_no_text(text)
      end
    end
  end
end
