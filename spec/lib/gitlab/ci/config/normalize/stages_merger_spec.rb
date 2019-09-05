# frozen_string_literal: true

require 'fast_spec_helper'

describe Gitlab::Ci::Config::Normalize::StagesMerger do
  let(:base_config) { { stages: %w[test deploy] } }
  let(:additional_config) { { stages: ['staging'] } }

  describe '#normalize_stages' do
    subject { described_class.new(base_config, additional_config).normalize_stages }

    it 'merges the stages' do
      expect(subject).to include(:stages)
      expect(subject[:stages]).to include('test', 'deploy', 'staging')
    end
  end
end
