# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Config::Normalize::ConfigMerger do
  let(:base_config) { { stages: base_stages, job_name: { script: 'echo hello' } } }
  let(:additional_config) { { stages: additional_stages, other_job_name: { script: 'echo other_hello' } } }

  before do
    stub_feature_flags(merge_stages_across_includes: true)
  end

  describe '#merge' do
    let(:base_stages) { %w[build test deploy production] }
    let(:additional_stages) { %w[deploy staging production] }

    subject { described_class.new(base_config, additional_config).merge }

    it 'deep merges everything except stages' do
      expected_hash = base_config.except(:stages).deep_merge(additional_config.except(:stages))

      expect(subject.except(:stages)).to eq(expected_hash)
    end

    it 'tsort merges stages' do
      expect(subject[:stages]).to eq(%w[build test deploy staging production])
    end

    context 'when the stages configuration is conflicting' do
      let(:base_stages) { %w[build test] }
      let(:additional_stages) { %w[test build] }

      it 'raises an error' do
        expect { subject }.to raise_error(described_class::StageMergeError)
      end
    end
  end
end
