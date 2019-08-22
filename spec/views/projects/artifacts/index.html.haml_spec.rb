# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "projects/artifacts/index.html.haml" do
  let(:project) { build(:project) }

  describe 'delete button' do
    before do
      pipeline = create(:ci_empty_pipeline, project: project)
      build = create(:ci_build, pipeline: pipeline, name: 'job1')
      create(:ci_job_artifact, job: build, size: 2 * 10**9)

      allow(view).to receive(:current_user).and_return(user)
      assign(:project, project)
      assign(:jobs_with_artifacts, Ci::Build.with_sum_artifacts_size)
      assign(:total_size, 0)
      assign(:sort, 'created_asc')
    end

    context 'with admin' do
      let(:user) { build(:admin) }

      it 'has a delete button' do
        render

        expect(rendered).to have_link('Delete artifacts')
      end
    end

    context 'with owner' do
      let(:user) { create(:user) }
      let(:project) { build(:project, namespace: user.namespace) }

      it 'has a delete button' do
        render

        expect(rendered).to have_link('Delete artifacts')
      end
    end

    context 'with master' do
      let(:user) { create(:user) }

      it 'has a delete button' do
        allow_any_instance_of(ProjectTeam).to receive(:max_member_access).and_return(Gitlab::Access::MASTER)
        render

        expect(rendered).to have_link('Delete artifacts')
      end
    end

    context 'with developer' do
      let(:user) { build(:user) }

      it 'has no delete button' do
        project.add_developer(user)
        render

        expect(rendered).not_to have_link('Delete artifacts')
      end
    end

    context 'with reporter' do
      let(:user) { build(:user) }

      it 'has no delete button' do
        project.add_reporter(user)
        render

        expect(rendered).not_to have_link('Delete artifacts')
      end
    end
  end
end
