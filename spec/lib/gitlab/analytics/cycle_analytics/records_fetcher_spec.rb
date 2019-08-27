# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Analytics::CycleAnalytics::RecordsFetcher do
  around do |example|
    Timecop.freeze { example.run }
  end

  let(:project) { create(:project, :empty_repo) }
  let(:user) { create(:user) }

  subject do
    Gitlab::Analytics::CycleAnalytics::DataCollector.new(
      stage: stage,
      params: {
        from: 1.year.ago,
        current_user: user
      }
    ).records_fetcher.serialized_records
  end

  describe '#serialized_records' do
    describe 'for issue based stage' do
      let(:issue1) { create(:issue, project: project) }
      let(:issue2) { create(:issue, project: project, confidential: true) }
      let(:stage) do
        build(:cycle_analytics_project_stage, {
          start_event_identifier: :plan_stage_start,
          end_event_identifier: :issue_first_mentioned_in_commit,
          project: project
        })
      end

      before do
        issue1.metrics.update(first_added_to_board_at: 3.days.ago)
        issue2.metrics.update(first_added_to_board_at: 3.days.ago)

        issue1.metrics.update!(first_mentioned_in_commit_at: 2.days.ago)
        issue2.metrics.update!(first_mentioned_in_commit_at: 2.days.ago)
      end

      it "respects issue visibility rules, confidential issues shouldn't be listed" do
        project.add_user(user, Gitlab::Access::GUEST)

        expect(subject.size).to eq(1)
        expect(subject.first[:iid].to_s).to eq(issue1.iid.to_s)
      end

      it 'returns all records when user is a maintainer' do
        project.add_user(user, Gitlab::Access::MAINTAINER)

        expect(subject.size).to eq(2)
      end
    end

    describe 'for merge request based stage' do
      let(:mr1) { create(:merge_request, created_at: 5.days.ago, source_project: project, allow_broken: true) }
      let(:mr2) { create(:merge_request, created_at: 5.days.ago, source_project: project, allow_broken: true) }
      let(:stage) do
        build(:cycle_analytics_project_stage, {
          start_event_identifier: :merge_request_created,
          end_event_identifier: :merge_request_merged,
          project: project
        })
      end

      before do
        mr1.metrics.update(merged_at: 3.days.ago)
        mr2.metrics.update(merged_at: 3.days.ago)
      end

      it 'returns all records when user is a maintainer' do
        project.add_user(user, Gitlab::Access::MAINTAINER)

        expect(subject.size).to eq(2)
      end
    end

    describe 'special case' do
      let(:mr1) { create(:merge_request, source_project: project, allow_broken: true) }
      let(:mr2) { create(:merge_request, source_project: project, allow_broken: true) }
      let(:ci_build1) { create(:ci_build) }
      let(:ci_build2) { create(:ci_build) }
      let(:default_stages) { Gitlab::Analytics::CycleAnalytics::DefaultStages }
      let(:stage) { build(:cycle_analytics_project_stage, default_stages.params_for_test_stage.merge(project: project)) }

      before do
        mr1.metrics.update!({
          merged_at: 5.days.ago,
          first_deployed_to_production_at: 1.day.ago,
          latest_build_started_at: 5.days.ago,
          latest_build_finished_at: 1.day.ago,
          pipeline: ci_build1.pipeline
        })
        mr2.metrics.update!({
          merged_at: 10.days.ago,
          first_deployed_to_production_at: 5.days.ago,
          latest_build_started_at: 9.days.ago,
          latest_build_finished_at: 7.days.ago,
          pipeline: ci_build2.pipeline
        })
      end

      it 'returns build records for default test stage' do
        expect(subject.size).to eq(2)

        build_ids = subject.map { |item| item[:id] }
        expect(build_ids).to eq([ci_build1.id, ci_build2.id])
      end

      it 'returns build records for default staging stage' do
        stage.assign_attributes(default_stages.params_for_staging_stage)

        expect(subject.size).to eq(2)

        build_ids = subject.map { |item| item[:id] }
        expect(build_ids).to eq([ci_build1.id, ci_build2.id])
      end
    end
  end
end
