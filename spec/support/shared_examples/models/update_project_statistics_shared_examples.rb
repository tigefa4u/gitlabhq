# frozen_string_literal: true

require 'spec_helper'

shared_context 'UpdateProjectStatisticsContext' do
  let(:project) { subject.project }
  let(:project_statistics_name) { described_class.project_statistics_name }
  let(:statistic_attribute) { described_class.statistic_attribute }

  def reload_stat
    project.statistics.reload.send(project_statistics_name).to_i
  end

  def read_attribute
    subject.read_attribute(statistic_attribute).to_i
  end

  it { is_expected.to be_new_record }
end

shared_examples_for 'UpdateProjectStatisticsAfterCreate' do
  include_context 'UpdateProjectStatisticsContext'

  context 'when creating' do
    it 'updates the project statistics' do
      delta = read_attribute

      expect { subject.save! }
        .to change { reload_stat }
        .by(delta)
    end

    it 'schedules a namespace statistics worker' do
      expect(Namespaces::ScheduleAggregationWorker)
        .to receive(:perform_async).once

      subject.save!
    end
  end
end

shared_examples_for 'UpdateProjectStatisticsAfterUpdate' do
  include_context 'UpdateProjectStatisticsContext'

  context 'when updating' do
    let(:delta) { 42 }

    before do
      subject.save!
    end

    it 'updates project statistics' do
      expect(ProjectStatistics)
        .to receive(:increment_statistic)
        .and_call_original

      subject.write_attribute(statistic_attribute, read_attribute + delta)

      expect { subject.save! }
        .to change { reload_stat }
        .by(delta)
    end

    it 'schedules a namespace statistics worker' do
      expect(Namespaces::ScheduleAggregationWorker)
        .to receive(:perform_async).once

      subject.write_attribute(statistic_attribute, read_attribute + delta)
      subject.save!
    end

    it 'avoids N + 1 queries' do
      subject.write_attribute(statistic_attribute, read_attribute + delta)

      control_count = ActiveRecord::QueryRecorder.new do
        subject.save!
      end

      subject.write_attribute(statistic_attribute, read_attribute + delta)

      expect do
        subject.save!
      end.not_to exceed_query_limit(control_count)
    end
  end
end

shared_examples_for 'UpdateProjectStatisticsAfterDestroy' do
  include_context 'UpdateProjectStatisticsContext'

  context 'when destroying' do
    before do
      subject.save!
    end

    it 'updates the project statistics' do
      delta = -read_attribute

      expect(ProjectStatistics)
        .to receive(:increment_statistic)
        .and_call_original

      expect { subject.job.destroy! }
        .to change { reload_stat }
        .by(delta)
    end

    it 'schedules a namespace statistics worker' do
      expect(Namespaces::ScheduleAggregationWorker)
        .to receive(:perform_async).once

      subject.job.destroy!
    end

    context 'when it is destroyed from the project level' do
      it 'does not update the project statistics' do
        expect(ProjectStatistics)
          .not_to receive(:increment_statistic)

        project.update(pending_delete: true)
        project.destroy!
      end

      it 'does not schedule a namespace statistics worker' do
        expect(Namespaces::ScheduleAggregationWorker)
          .not_to receive(:perform_async)

        project.update(pending_delete: true)
        project.destroy!
      end
    end
  end
end

shared_examples_for 'UpdateProjectStatistics' do
  include_context 'UpdateProjectStatisticsContext'

  it_behaves_like 'UpdateProjectStatisticsAfterCreate'
  it_behaves_like 'UpdateProjectStatisticsAfterUpdate'
  it_behaves_like 'UpdateProjectStatisticsAfterDestroy'
end
