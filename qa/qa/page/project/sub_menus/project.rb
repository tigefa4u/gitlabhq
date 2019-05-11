module QA
  module Page
    module Project
      module SubMenus
        module Project
          def self.included(base)
            base.class_eval do
              view 'app/views/layouts/nav/sidebar/_project.html.haml' do
                element :project_item
              end
            end
          end

          def click_project
            retry_on_exception do
              within_sidebar do
                click_element(:project_item)
              end
            end
          end
        end
      end
    end
  end
end
