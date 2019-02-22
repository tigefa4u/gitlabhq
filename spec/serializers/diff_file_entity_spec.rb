require 'spec_helper'

describe DiffFileEntity do
  include RepoHelpers

  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository }
  let(:commit) { project.commit(sample_commit.id) }
  let(:diff_refs) { commit.diff_refs }
  let(:diff) { commit.raw_diffs.first }
  let(:diff_file) { Gitlab::Diff::File.new(diff, diff_refs: diff_refs, repository: repository) }
  let(:entity) { described_class.new(diff_file, request: {}) }

  subject { entity.as_json }

  context 'when there is no merge request' do
    it_behaves_like 'diff file entity'
  end

  context 'when there is a merge request' do
    let(:user) { create(:user) }
    let(:request) { EntityRequest.new(project: project, current_user: user) }
    let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
    let(:entity) { described_class.new(diff_file, request: request, merge_request: merge_request) }
    let(:exposed_urls) { %i(edit_path view_path context_lines_path) }

    it_behaves_like 'diff file entity'

    it 'exposes additional attributes' do
      expect(subject).to include(*exposed_urls)
      expect(subject).to include(:replaced_view_path)
    end

    it 'points all urls to merge request target project' do
      response = subject

      exposed_urls.each do |attribute|
        expect(response[attribute]).to include(merge_request.target_project.to_param)
      end
    end

    it 'exposes load_collapsed_diff_url if the file viewer is collapsed' do
      allow(diff_file.viewer).to receive(:collapsed?) { true }

      expect(subject).to include(:load_collapsed_diff_url)
    end
  end
end
