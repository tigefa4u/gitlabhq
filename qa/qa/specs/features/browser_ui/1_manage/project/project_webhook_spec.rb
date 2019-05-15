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
          page.fill_webhook_url("http://#{webhook_service.hostname}:#{webhook_service.port}")
          page.check_push_events_checkbox
          page.check_merge_request_events_checkbox
          page.check_note_events_checkbox
          page.check_issue_events_checkbox
          page.uncheck_enable_ssl_verification_checkbox
          page.click_add_webhook_button
        end
      end
    end
  end
end
