# frozen_string_literal: true

module QA
  context 'Create', :smoke do
    describe 'Snippet creation' do
      it 'User creates a snippet' do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.perform(&:sign_in_using_credentials)

        Page::Main::Menu.perform(&:go_to_snippets)
        Page::Dashboard::Snippet::Index.perform(&:go_to_new_snippet_page)

        Resource::Snippet.fabricate_via_browser_ui! do |snippet|
          snippet.title = 'Snippet title'
          snippet.description = 'Snippet description'
          snippet.content = 'Snippet file text'
          snippet.type = 'Public'
        end

        Page::Dashboard::Snippet::Show.perform do |snippet|
          expect(snippet).to have_snippet_title('Snippet title')
          expect(snippet).to have_snippet_description('Snippet description')
          expect(snippet).to have_snippet_content('Snippet file text')
          expect(snippet).to have_embed_type('Embed')
        end
      end
    end
  end
end
