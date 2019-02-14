# frozen_string_literal: true

require 'spec_helper'

describe PrometheusQuery do
  subject { build(:prometheus_query) }

  it { is_expected.to belong_to(:prometheus_metric) }
  it { is_expected.to validate_presence_of(:query) }
  it { is_expected.to validate_presence_of(:unit) }

  describe '#to_query_hash' do
    let(:expected_hash) do
      {
        query_range: subject.query,
        unit: subject.unit,
        label: subject.legend
      }
    end

    specify { expect(subject.to_query_hash).to include expected_hash }
  end

  describe '#query_series' do
    specify { expect(subject.__send__(:query_series)).to be_nil }

    context 'when a status code is specified' do
      before do
        subject.legend = 'Status Code'
      end

      specify { expect(subject.__send__(:query_series)).to be_a Array }
    end
  end
end
