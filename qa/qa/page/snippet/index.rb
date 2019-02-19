module QA
  module Page
    module Snippet
      class Index < Page::Base
        view 'app/views/dashboard/_snippets_head.html.haml' do
          element :new_snippet_button
        end

        def go_to_new_snippet_page
          click_element :new_snippet_button
        end
      end
    end
  end
end
