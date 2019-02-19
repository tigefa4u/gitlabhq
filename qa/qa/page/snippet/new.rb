module QA
  module Page
    module Snippet
      class New < Page::Base
        view 'app/views/snippets/new.html.haml' do
          element :new_snippet_title
          element :issuable_form_description
          element :create_snippet_button
        end

        def fill_title(title)
          fill_element :new_snippet_title, title
        end

        def fill_description(description)
          fill_element :issuable_form_description, description
        end

        def add_snippet_content(content)
          text_area.set content
        end

        def create_snippet
          click_element :create_snippet_button
        end

        private

        def text_area
          find('#editor>textarea', visible: false)
        end
      end
    end
  end
end
