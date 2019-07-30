# frozen_string_literal: true

require 'spec_helper'

describe Git::ExternalMergeRequestHooksService, :service do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }

  let(:oldrev) { Gitlab::Git::BLANK_SHA }
  let(:newrev) { "8a2a6eb295bb170b34c24c76c49ed0e9b2eaf34b" }
  let(:ref) { 'refs/pull/123' }

  let(:commits) { project.repository.commits(ref) }

  let(:service) do
    described_class.new(project, user, oldrev: oldrev, newrev: newrev, ref: ref)
  end

  it 'update remote mirrors' do
    expect(service).to receive(:update_remote_mirrors).and_call_original

    service.execute
  end

  describe 'System hooks' do
    it 'Executes system hooks' do
      push_data = service.execute

      expect_next_instance_of(SystemHooksService) do |system_hooks_service|
        expect(system_hooks_service)
          .to receive(:execute_hooks)
          .with(push_data, :tag_push_hooks)
      end

      service.execute
    end
  end

  describe "Webhooks" do
    it "executes hooks on the project" do
      expect(project).to receive(:execute_hooks)

      service.execute
    end
  end

  describe "Pipelines" do
    before do
      stub_ci_pipeline_to_return_yaml_file
      project.add_developer(user)
    end

    it "creates a new pipeline" do
      expect { service.execute }.to change { Ci::Pipeline.count }

      expect(Ci::Pipeline.last).to be_external_merge_request?
    end
  end

  describe 'Push data' do
    subject(:push_data) { service.execute }
    it 'has expected push data attributes' do
      is_expected.to match a_hash_including(
        object_kind: 'push',
        ref: ref,
        before: oldrev,
        after: newrev,
        message: nil,
        user_id: user.id,
        user_name: user.name,
        project_id: project.id
      )
    end

    context "with repository data" do
      subject { push_data[:repository] }

      it 'has expected repository attributes' do
        is_expected.to match a_hash_including(
          name: project.name,
          url: project.url_to_repo,
          description: project.description,
          homepage: project.web_url
        )
      end
    end
  end
end
