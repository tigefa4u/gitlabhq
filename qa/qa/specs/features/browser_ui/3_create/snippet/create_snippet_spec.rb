# frozen_string_literal: true

module QA
  context 'Create', :smoke do
    describe 'Snippet createon' do
      it 'User creates a snippet' do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.act { sign_in_using_credentials }

        Page::Dashboard::Projects.act { go_to_snippets }
        Page::Snippet::Index.act { go_to_new_snippet_page }

        expect(find_field('Private')).to be_checked

        Resource::Snippet.fabricate! do |snippet|
          snippet.title = 'Snippet title'
          snippet.description = 'Snippet description'
          snippet.content = 'Snippet file text'
        end

        expect(page).to have_content('Snippet title')
        expect(page).to have_content('Snippet description')
        expect(page).to have_content('Snippet file text')
      end
    end
  end
end
