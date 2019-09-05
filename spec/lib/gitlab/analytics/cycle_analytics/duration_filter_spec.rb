# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Analytics::CycleAnalytics::DurationFilter do
  let(:stage_params) { {} }
  let(:stage) { Analytics::CycleAnalytics::ProjectStage.new(stage_params) }
  subject { described_class.new(stage: stage) }

  describe 'when duration filtering is skipped' do
    %I[issue test review staging production].each do |stage_name|
      it "for '#{stage_name}' stage" do
        stage_params.merge!(Gitlab::Analytics::CycleAnalytics::DefaultStages.public_send("params_for_#{stage_name}_stage"))

        input_query = stage.subject_model.all
        output_query = subject.apply(input_query)

        expect(input_query).to eq(output_query)
      end
    end
  end
end
