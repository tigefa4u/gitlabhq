# frozen_string_literal: true

require 'rails_helper'

describe Analytics::CycleAnalytics::StageDecorator do
  let(:params) { Gitlab::Analytics::CycleAnalytics::DefaultStages.params_for_issue_stage }

  it 'decorates default stage attributes with localized text' do
    issue_stage = Analytics::CycleAnalytics::ProjectStage.new(params)

    decorator = described_class.new(issue_stage)

    expect(decorator.title).to eq(described_class::DEFAULT_STAGE_ATTRIBUTES[:issue][:title].call)
    expect(decorator.description).to eq(described_class::DEFAULT_STAGE_ATTRIBUTES[:issue][:description].call)
  end

  describe 'custom stage' do
    let(:custom_stage) { Analytics::CycleAnalytics::ProjectStage.new(params) }
    let(:decorator) { described_class.new(custom_stage) }

    before do
      params[:name] = 'My Stage'
    end

    it 'uses name attribute for the title' do
      expect(decorator.title).to eq(params[:name])
    end

    it 'uses empty string for description' do
      expect(decorator.description).to eq('')
    end
  end

  it 'infers legend from #subject_model' do
    issue_stage = Analytics::CycleAnalytics::ProjectStage.new(params)

    expect(issue_stage.subject_model).to eq(Issue)

    decorator = described_class.new(issue_stage)
    expect(decorator.legend).to eq(_("Related Issues"))
  end
end
