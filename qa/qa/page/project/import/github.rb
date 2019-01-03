module QA
  module Page
    module Project
      module Import
        class Github < Page::Base
          include Page::Component::Select2

          view 'app/views/import/github/new.html.haml' do
            element :personal_access_token_field, 'text_field_tag :personal_access_token' # rubocop:disable QA/ElementWithPattern
            element :list_repos_button, "submit_tag _('List your GitHub repositories')" # rubocop:disable QA/ElementWithPattern
          end

          view 'app/views/import/_githubish_status.html.haml' do
            element :project_import_row, 'data: { qa: { repo_path: repo.full_name } }' # rubocop:disable QA/ElementWithPattern
            element :project_namespace_select
            element :project_namespace_field, 'select_tag :namespace_id' # rubocop:disable QA/ElementWithPattern
            element :project_path_field, 'text_field_tag :path, sanitize_project_name(repo.name)' # rubocop:disable QA/ElementWithPattern
            element :import_button, "_('Import')" # rubocop:disable QA/ElementWithPattern
          end

          def add_personal_access_token(personal_access_token)
            fill_in 'personal_access_token', with: personal_access_token
          end

          def list_repos
            click_button 'List your GitHub repositories'
          end

          def import!(full_path, name)
            choose_test_namespace(full_path)
            set_path(full_path, name)
            import_project(full_path)
            wait_for_success
          end

          private

          def within_repo_path(full_path)
            wait(reload: false) do
              !all_elements(:project_import_row).empty?
            end

            project_import_row = all_elements(:project_import_row).detect { |row| row.has_css?('a', text: full_path, wait: 1.0)}

            within(project_import_row) do
              yield
            end
          end

          def choose_test_namespace(full_path)
            within_repo_path(full_path) do
              click_element :project_namespace_select
            end

            search_and_select(Runtime::Namespace.path)
          end

          def set_path(full_path, name)
            within_repo_path(full_path) do
              fill_element(:project_path_field, name)
            end
          end

          def import_project(full_path)
            within_repo_path(full_path) do
              click_element(:import_button)
            end
          end

          def wait_for_success
            wait(max: 60, time: 1.0, reload: false) do
              page.has_content?('Done', wait: 1.0)
            end
          end
        end
      end
    end
  end
end
