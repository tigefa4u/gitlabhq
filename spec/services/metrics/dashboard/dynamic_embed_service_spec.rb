# frozen_string_literal: true

require 'spec_helper'

describe Metrics::Dashboard::DynamicEmbedService, :use_clean_rails_memory_store_caching do
  include MetricsDashboardHelpers

  set(:project) { build(:project) }
  set(:user) { create(:user) }
  set(:environment) { create(:environment, project: project) }

  before do
    project.add_maintainer(user)
  end

  describe '#get_dashboard' do
    let(:dashboard_path) { '.gitlab/dashboards/test.yml' }
    let(:group) { 'Group A' }
    let(:title) { 'Super Chart A1' }
    let(:y_label) { 'y_label' }

    let(:service_params) do
      [
        project,
        user,
        {
          environment: environment,
          dashboard_path: dashboard_path,
          group: group,
          title: title,
          y_label: y_label
        }
      ]
    end

    let(:service_call) { described_class.new(*service_params).get_dashboard }

    context 'when the dashboard does not exist' do
      it_behaves_like 'misconfigured dashboard service response', :not_found
    end

    context 'when the dashboard is exists' do
      let(:project) { project_with_dashboard(dashboard_path) }

      it_behaves_like 'valid embedded dashboard service response'
      it_behaves_like 'raises error for users with insufficient permissions'

      it 'caches the unprocessed dashboard for subsequent calls' do
        expect(YAML).to receive(:safe_load).once.and_call_original

        described_class.new(*service_params).get_dashboard
        described_class.new(*service_params).get_dashboard
      end

      context 'when the specified group is not present on the dashboard' do
        let(:group) { 'Group Not Found' }

        it_behaves_like 'misconfigured dashboard service response', :not_found
      end

      context 'when the specified title is not present on the dashboard' do
        let(:title) { 'Title Not Found' }

        it_behaves_like 'misconfigured dashboard service response', :not_found
      end

      context 'when the specified y-axis label is not present on the dashboard' do
        let(:y_label) { 'Y-Axis Not Found' }

        it_behaves_like 'misconfigured dashboard service response', :not_found
      end
    end
  end
end
