# frozen_string_literal: true

module QA
  module Page
    module Profile
      class SSHKey < Page::Base
        view 'app/views/profiles/keys/_key_details.html.haml' do
          element :key_fingerprint_code
        end

        def fingerprint
          element_text(:key_fingerprint_code)
        end
      end
    end
  end
end
