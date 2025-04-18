# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe ::Gitlab::Ci::Pipeline::Metrics do
  describe '.pipeline_creation_step_duration_histogram' do
    around do |example|
      described_class.clear_memoization(:pipeline_creation_step_histogram)

      example.run

      described_class.clear_memoization(:pipeline_creation_step_histogram)
    end

    it 'adds the step to the step duration histogram' do
      expect(::Gitlab::Metrics).to receive(:histogram)
        .with(
          :gitlab_ci_pipeline_creation_step_duration_seconds,
          'Duration of each pipeline creation step',
          { step: nil },
          [0.01, 0.05, 0.1, 0.5, 1.0, 2.0, 5.0, 10.0, 15.0, 20.0, 50.0, 240.0]
        )

      described_class.pipeline_creation_step_duration_histogram
    end
  end

  describe '.job_token_authorization_failures_counter' do
    it 'returns a counter for job token authorization failures' do
      expect(::Gitlab::Metrics).to receive(:counter)
        .with(
          :gitlab_ci_job_token_authorization_failures,
          'Count of job token authorization failures',
          { same_root_ancestor: false }
        )

      described_class.job_token_authorization_failures_counter
    end
  end
end
