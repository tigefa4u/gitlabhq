# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Status::Build::Common, feature_category: :continuous_integration do
  let_it_be(:user) { create(:user) }
  let_it_be(:build) { create(:ci_build) }
  let(:project) { build.project }

  subject do
    Gitlab::Ci::Status::Core
      .new(build, user)
      .extend(described_class)
  end

  describe '#has_action?' do
    it { is_expected.not_to have_action }
  end

  describe '#has_details?' do
    context 'when user has access to read build' do
      before do
        project.add_developer(user)
      end

      it { is_expected.to have_details }
    end

    context 'when user does not have access to read build' do
      before do
        project.update!(public_builds: false)
      end

      it { is_expected.not_to have_details }
    end
  end

  describe '#details_path' do
    context 'when user has access to read build' do
      before do
        project.add_developer(user)
      end

      it 'links to the build details page' do
        expect(subject.details_path).to include "jobs/#{build.id}"
      end
    end

    context 'when user has no access to read build' do
      before do
        project.update!(public_builds: false)
      end

      it 'is nil' do
        expect(subject.details_path).to be_nil
      end
    end
  end

  describe '#illustration' do
    it 'provides a fallback empty state illustration' do
      expect(subject.illustration).not_to be_empty
    end
  end
end
