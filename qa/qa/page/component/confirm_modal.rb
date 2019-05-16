module QA
  module Page
    module Component
      module ConfirmModal
        def self.included(base)
          base.view 'app/views/shared/_confirm_modal.html.haml' do
            element :confirm_modal
            element :confirm_input
            element :confirm_button
          end
        end

        def add_confirmation_info(text)
          fill_element :confirm_input, text
        end

        def submit_confirmation
          click_element :confirm_button
        end
      end
    end
  end
end
