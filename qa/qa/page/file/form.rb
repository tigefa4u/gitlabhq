# frozen_string_literal: true

module QA
  module Page
    module File
      class Form < Page::Base
        include Shared::CommitMessage
        include Page::Component::DropdownFilter
        include Shared::CommitButton
        include Shared::Editor

        view 'app/views/projects/blob/_editor.html.haml' do
          element :file_name, "text_field_tag 'file_name'" # rubocop:disable QA/ElementWithPattern
        end

        view 'app/views/projects/blob/_template_selectors.html.haml' do
          element :gitignore_dropdown
          element :gitlab_ci_yml_dropdown
          element :dockerfile_dropdown
          element :license_dropdown
        end

        def add_name(name)
          fill_in 'file_name', with: name
        end
      end
    end
  end
end
