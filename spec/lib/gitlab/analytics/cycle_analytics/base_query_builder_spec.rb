# frozen_string_literal: true

require 'rails_helper'

describe Gitlab::Analytics::CycleAnalytics::BaseQueryBuilder do
  let(:project) { create(:project, :empty_repo) }
  let(:mr1) { create(:merge_request, source_project: project, allow_broken: true, created_at: 3.months.ago) }
  let(:mr2) { create(:merge_request, source_project: project, allow_broken: true, created_at: 1.month.ago) }
  let(:params) { {} }
  let(:records) do
    stage = build(:cycle_analytics_project_stage, {
      start_event_identifier: :merge_request_created,
      end_event_identifier: :merge_request_merged,
      project: project
    })
    described_class.new(stage: stage, params: params).run.to_a
  end

  before do
    mr1.metrics.update!(merged_at: 1.month.ago)
    mr2.metrics.update!(merged_at: Time.now)
  end

  around do |example|
    Timecop.freeze { example.run }
  end

  describe 'date range parameters' do
    it "filters by only the 'from' parameter" do
      params[:from] = 4.months.ago

      expect(records.size).to eq(2)
    end

    it "filters by both 'from' and 'to' parameters" do
      params.merge!(from: 4.months.ago, to: 2.months.ago)

      expect(records.size).to eq(1)
    end

    it 'filters out everything when invalid date range is provided' do
      params.merge!(from: 1.month.ago, to: 10.months.ago)

      expect(records.size).to eq(0)
    end
  end

  it 'scopes query within a project' do
    other_mr = create(:merge_request, source_project: create(:project), allow_broken: true, created_at: 3.months.ago)
    other_mr.metrics.update!(merged_at: 1.month.ago)

    params[:from] = 1.year.ago

    expect(records.size).to eq(2)
  end
end
