# frozen_string_literal: true

module QA
  context 'Manage', :docker do
    describe 'Project Webhooks' do
      let(:name) { "calls-counter-api-service" }

      after do
        Service::Runner.new(name).remove!
      end

      it 'project calls webhooks on specified events' do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.act { sign_in_using_credentials }

        webhook_service = Service::Webhook.new(name).tap(&:run!)

        project = Resource::Project.fabricate! do |project|
          project.name = 'awesome-project'
          project.description = 'create awesome project test'
        end

        project.visit!

        Page::Project::Menu.perform(&:go_to_integration_settings)

        Page::Project::Settings::Integrations.perform do |page|
          page.fill_webhook_url("http://#{webhook_service.hostname}:#{webhook_service.port}/api/calls")
          page.check_push_events_checkbox
          page.check_merge_request_events_checkbox
          page.check_note_events_checkbox
          page.check_issue_events_checkbox
          page.uncheck_enable_ssl_verification_checkbox
          page.click_add_webhook_button
        end

        expect(webhook_service.calls_count).to eq 0

        Resource::Issue.fabricate! do |issue|
          issue.project = project
          issue.title = "An issue title"
        end

        Support::Waiter.wait(max: 10, interval: 1) do
          webhook_service.calls_count == 1
        end

        expect(webhook_service.last_call_event_type).to eq "issue"

        Page::Project::Issue::Show.perform do |show_page|
          show_page.comment('This is a comment')
        end

        Support::Waiter.wait(max: 10, interval: 1) do
          webhook_service.calls_count == 2
        end

        expect(webhook_service.last_call_event_type).to eq "note"

        Resource::Repository::ProjectPush.fabricate! do |push|
          push.project = project
          push.file_name = 'README.md'
          push.file_content = '# This is a test project'
          push.commit_message = 'Add README.md'
        end

        Support::Waiter.wait(max: 10, interval: 1) do
          webhook_service.calls_count == 3
        end

        expect(webhook_service.last_call_event_type).to eq "push"
      end
    end
  end
end
