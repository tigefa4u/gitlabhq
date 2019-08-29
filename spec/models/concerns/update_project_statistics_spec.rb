# frozen_string_literal: true

require 'spec_helper'

describe UpdateProjectStatistics do
  describe '.update_project_statistics!' do
    let(:project) { create(:project) }

    subject do
      described_class.update_project_statistics!(project, :build_artifacts_size, 100)
    end

    context 'when project is not pending delete' do
      it 'increments project statistics' do
        expect(ProjectStatistics).to receive(:increment_statistic).with(project.id, :build_artifacts_size, 100)

        subject
      end

      context 'when update_statistics_namespace is enabled' do
        before do
          stub_feature_flags(update_statistics_namespace: true)
        end

        it 'schedules the aggregation worker' do
          expect(Namespaces::ScheduleAggregationWorker).to receive(:perform_async).with(project.namespace_id)

          subject
        end
      end

      context 'when update_statistics_namespace is not enabled' do
        before do
          stub_feature_flags(update_statistics_namespace: false)
        end

        it 'does not schedule the aggregation worker' do
          expect(Namespaces::ScheduleAggregationWorker).not_to receive(:perform_async).with(project.namespace_id)

          subject
        end
      end
    end

    context 'when project is pending delete' do
      before do
        project.pending_delete = true
      end

      it 'does not increment project statistics' do
        expect(ProjectStatistics).not_to receive(:increment_statistics).with(project.id, 'dummy_name', 100)

        subject
      end
    end
  end
end
