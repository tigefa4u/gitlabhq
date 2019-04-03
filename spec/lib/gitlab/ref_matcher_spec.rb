# frozen_string_literal: true

require 'fast_spec_helper'
require 'rspec-parameterized'

describe Gitlab::RefMatcher do
  describe '#matches?' do
    using RSpec::Parameterized::TableSyntax

    where(:pattern, :ref, :result) do
      'v*'             | 'v1.1.1'    | true
      'v*[e]'          | 'v1.1.1-ee' | true
      'v[0-9].*'       | 'v1.1.1'    | true
      'v[2-9].*'       | 'v1.1.1'    | false
      'v*-ee'          | 'v1.1.1-ee' | true
      'v*[^e]'         | 'v1.1.1-ee' | false
      'v*[^-][^e][^e]' | 'v1.1.1-ee' | false
    end
  
    with_them do
      subject { described_class.new(pattern).matches?(ref) }

      it { is_expected.to eq(result) }
    end
  end
end
