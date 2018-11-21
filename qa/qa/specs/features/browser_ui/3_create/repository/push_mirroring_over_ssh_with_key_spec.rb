# frozen_string_literal: true

module QA
  context 'Create' do
    describe 'Push mirror a repository over SSH with a private key' do
      it 'configures and syncs a (push) mirrored repository' do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.perform(&:sign_in_using_credentials)

        target_project = Resource::Project.fabricate! do |project|
          project.name = 'push-mirror-target-project'
        end
        target_project_uri = target_project.repository_ssh_location.uri

        source_project_push = Resource::Repository::ProjectPush.fabricate! do |push|
          push.file_name = 'README.md'
          push.file_content = '# This is a test project'
          push.commit_message = 'Add README.md'
        end
        source_project_push.project.visit!

        # Configure the source project to push to the target project and get
        # the public key to be used as a deploy key
        Page::Project::Menu.perform(&:go_to_repository_settings)
        public_key = Page::Project::Settings::Repository.perform do |settings|
          settings.expand_mirroring_repositories do |mirror_settings|
            mirror_settings.repository_url = target_project_uri
            mirror_settings.mirror_direction = 'Push'
            mirror_settings.authentication_method = 'SSH public key'
            mirror_settings.detect_host_keys
            mirror_settings.mirror_repository
            mirror_settings.public_key target_project_uri
          end
        end

        # Add the public key to the target project as a deploy key
        Resource::DeployKey.fabricate! do |resource|
          resource.project = target_project
          resource.title = "push mirror key #{Time.now.to_f}"
          resource.key = public_key
          resource.allow_write_access = true
        end

        # Sync the repositories
        source_project_push.project.visit!
        Page::Project::Menu.perform(&:go_to_repository_settings)
        Page::Project::Settings::Repository.perform do |settings|
          settings.expand_mirroring_repositories do |mirror_settings|
            mirror_settings.update target_project_uri
          end
        end

        # Check that the target project has the commit from the source
        target_project.visit!
        expect(page).to have_content('README.md')
        expect(page).to have_content('This is a test project')
      end
    end
  end
end
