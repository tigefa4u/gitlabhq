# frozen_string_literal: true

module QA
  module Page
    module Project
      module Settings
        class Integrations < Page::Base
          view 'app/views/shared/web_hooks/_form.html.haml' do
            element :webhook_url_field
            element :push_events_checkbox
            element :merge_request_events_checkbox
            element :note_events_checkbox
            element :issue_events_checkbox
            element :enable_ssl_verification_checkbox
          end

          view 'app/views/projects/hooks/_index.html.haml' do
            element :add_webhook_button
          end

          def fill_webhook_url(url)
            fill_element :webhook_url_field, url
          end

          def check_push_events_checkbox
            check_element :push_events_checkbox
          end

          def check_merge_request_events_checkbox
            check_element :merge_request_events_checkbox
          end

          def check_note_events_checkbox
            check_element :note_events_checkbox
          end

          def check_issue_events_checkbox
            check_element :issue_events_checkbox
          end

          def uncheck_enable_ssl_verification_checkbox
            uncheck_element :enable_ssl_verification_checkbox
          end

          def click_add_webhook_button
            click_element :add_webhook_button
          end
        end
      end
    end
  end
end
