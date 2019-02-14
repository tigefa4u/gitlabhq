# frozen_string_literal: true

require 'spec_helper'

describe HasRef do
  describe '#branch?' do
    let(:build) { create(:ci_build) }

    subject { build.branch? }

    context 'is not a tag' do
      before do
        build.tag = false
      end

      it 'return true' do
        is_expected.to be_truthy
      end
    end

    context 'is a tag' do
      before do
        build.tag = true
      end

      it 'return false' do
        is_expected.to be_falsey
      end
    end

    context 'when build is associated with a merge request' do
      before do
        allow(build).to receive(:merge_request?) { true }
      end

      it 'return false' do
        is_expected.to be_falsey
      end
    end
  end

  describe '#git_ref' do
    subject { build.git_ref }

    context 'when tag is true' do
      let(:build) { create(:ci_build, tag: true) }

      it 'returns a tag ref' do
        is_expected.to start_with(Gitlab::Git::TAG_REF_PREFIX)
      end
    end

    context 'when tag is false' do
      let(:build) { create(:ci_build, tag: false) }

      it 'returns a branch ref' do
        is_expected.to start_with(Gitlab::Git::BRANCH_REF_PREFIX)
      end
    end

    context 'when tag is nil' do
      let(:build) { create(:ci_build, tag: nil) }

      it 'returns a branch ref' do
        is_expected.to start_with(Gitlab::Git::BRANCH_REF_PREFIX)
      end
    end

    context 'when build is associated with a merge request' do
      let(:build) { create(:ci_build, tag: false) }

      before do
        allow(build).to receive(:merge_request?) { true }
      end

      it 'returns a branch ref' do
        is_expected.to start_with(Gitlab::Git::BRANCH_REF_PREFIX)
      end
    end
  end

  describe '#ref_type' do
    subject { build.ref_type }

    context 'when ref is branch' do
      let(:build) { create(:ci_build, tag: false) }

      it 'returns a correct ref type' do
        is_expected.to eq('branch')
      end
    end

    context 'when ref is tag' do
      let(:build) { create(:ci_build, tag: true) }

      it 'returns a correct ref type' do
        is_expected.to eq('tag')
      end
    end

    context 'when build is associated with a merge request' do
      let(:build) { create(:ci_build, tag: false) }

      before do
        allow(build).to receive(:merge_request?) { true }
      end

      it 'returns a correct ref type' do
        is_expected.to eq('branch')
      end
    end
  end

  describe '#refspecs' do
    subject { build.refspecs }

    context 'when depth is specified' do
      before do
        allow(build).to receive(:git_depth) { 1 }
      end

      context 'when ref is branch' do
        let(:build) { create(:ci_build, tag: false) }

        it 'returns correct refspecs' do
          is_expected.to include("+refs/heads/#{build.ref}:refs/remotes/origin/#{build.ref}")
        end
      end

      context 'when ref is tag' do
        let(:build) { create(:ci_build, tag: true) }

        it 'returns correct refspecs' do
          is_expected.to include("+refs/tags/#{build.ref}:refs/tags/#{build.ref}")
        end
      end

      context 'when build is associated with a merge request' do
        let(:build) { create(:ci_build, tag: false) }

        before do
          allow(build).to receive(:merge_request?) { true }
        end

        it 'returns correct refspecs' do
          is_expected.to include("+refs/heads/#{build.ref}:refs/remotes/origin/#{build.ref}")
        end
      end
    end

    context 'when depth is not specified' do
      context 'when ref is branch' do
        let(:build) { create(:ci_build, tag: false) }

        it 'returns correct refspecs' do
          is_expected.to contain_exactly('+refs/heads/*:refs/remotes/origin/*',
                                         '+refs/tags/*:refs/tags/*')
        end
      end

      context 'when ref is tag' do
        let(:build) { create(:ci_build, tag: true) }

        it 'returns correct refspecs' do
          is_expected.to contain_exactly('+refs/heads/*:refs/remotes/origin/*',
                                         '+refs/tags/*:refs/tags/*')
        end
      end

      context 'when build is associated with a merge request' do
        let(:build) { create(:ci_build, tag: false) }

        before do
          allow(build).to receive(:merge_request?) { true }
        end

        it 'returns correct refspecs' do
          is_expected.to contain_exactly('+refs/heads/*:refs/remotes/origin/*',
                                         '+refs/tags/*:refs/tags/*')
        end
      end
    end
  end
end
