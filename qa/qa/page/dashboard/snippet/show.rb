module QA
  module Page
    module Dashboard
      module Snippet
        class Show < Page::Base
          view 'app/views/shared/snippets/_header.html.haml' do
            element :snippet_title
            element :snippet_description
            element :embed_type
          end

          view 'app/views/shared/_file_highlight.html.haml' do
            element :file_content
          end

          def has_snippet_title?(snippet_title)
            within_element(:snippet_title) do
              has_text?(snippet_title)
            end
          end

          def has_snippet_description?(snippet_description)
            within_element(:snippet_description) do
              has_text?(snippet_description)
            end
          end

          def has_snippet_content?(snippet_content)
            finished_loading?
            within_element(:file_content) do
              has_text?(snippet_content)
            end
          end

          def has_embed_type?(embed_type)
            within_element(:embed_type) do
              has_text?(embed_type)
            end
          end
        end
      end
    end
  end
end
