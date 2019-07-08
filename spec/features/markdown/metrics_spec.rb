# frozen_string_literal: true
require 'spec_helper'

describe 'Metrics rendering' do
  include PrometheusHelpers

  let(:user) { create(:user) }
  let(:project) { create(:prometheus_project) }
  let(:pipeline) { create(:ci_pipeline, project: project) }
  let(:build) { create(:ci_build, pipeline: pipeline) }
  let(:environment) { create(:environment, project: project) }
  let(:current_time) { Time.now.utc }

  before do
    project.add_developer(user)
    create(:deployment, environment: environment, deployable: build)
    stub_all_prometheus_requests(environment.slug)

    sign_in(user)
  end

  around do |example|
    Timecop.freeze(current_time) { example.run }
  end

  context 'with deployments and related deployable present' do
    it 'shows embedded metrics' do
      description = metrics_namespace_project_environment_url(user, project, environment)

      project = create(:project, :public)
      issue = create(:issue, project: project, description: description)

      visit project_issue_path(project, issue)

      expect(page).to have_css('div#prometheus-graph')
    end
  end
end
