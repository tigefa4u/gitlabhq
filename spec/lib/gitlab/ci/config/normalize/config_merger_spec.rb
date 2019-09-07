# frozen_string_literal: true

require 'fast_spec_helper'

describe Gitlab::Ci::Config::Normalize::ConfigMerger do
  let(:base_config) { { stages: %w[build test deploy production], job_name: { script: 'echo hello' } } }
  let(:additional_config) { { stages: %w[deploy staging production], other_job_name: { script: 'echo other_hello' } } }

  describe '#merge' do
    subject { described_class.new(base_config, additional_config).merge }

    it 'deep merges everything except stages' do
      expected_hash = base_config.except(:stages).deep_merge(additional_config.except(:stages))

      expect(subject.except(:stages)).to eq(expected_hash)
    end

    it 'tsort merges stages' do
      expect(subject[:stages]).to eq(%w[build test deploy staging production])
    end
  end
end
