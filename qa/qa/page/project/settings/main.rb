# frozen_string_literal: true
module QA
  module Page
    module Project
      module Settings
        class Main < Page::Base
          include Common
          include Component::Select2
          include Component::ConfirmModal
          include SubMenus::Common
          include SubMenus::Project

          view 'app/views/projects/edit.html.haml' do
            element :advanced_settings
            element :transfer_button
          end

          view 'app/views/projects/settings/_general.html.haml' do
            element :project_name_field
            element :save_naming_topics_avatar_button
          end

          def rename_project_to(name)
            fill_project_name(name)
            click_save_changes
          end

          def fill_project_name(name)
            fill_element :project_name_field, name
          end

          def click_save_changes
            click_element :save_naming_topics_avatar_button
          end

          def expand_advanced_settings(&block)
            expand_section(:advanced_settings) do
              Advanced.perform(&block)
            end
          end

          def select_transfer_option(namespace)
            search_and_select(namespace)
          end

          def transfer_project!(project_name, namespace)
            select_transfer_option(namespace)
            click_element(:transfer_button)
            add_confirmation_info(project_name)
            submit_confirmation
          end
        end
      end
    end
  end
end
