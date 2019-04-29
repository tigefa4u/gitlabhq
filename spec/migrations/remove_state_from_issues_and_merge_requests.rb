require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20190429112834_remove_state_from_issues_and_merge_requests.rb')

describe RemoveStateFromIssuesAndMergeRequests, :migration do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:merge_requests) { table(:merge_requests) }
  let(:issues) { table(:issues) }
  let(:migration) { described_class.new }
  let(:group) { namespaces.create!(name: 'gitlab', path: 'gitlab') }
  let(:project) { projects.create!(namespace_id: group.id) }

  describe '#down' do
    before do
      migration.up
    end

    context 'issues' do
      it 'migrates state_id column to old state' do
        #expect(migration.index_exists?(:project_features, :project_id, unique: true, name: 'index_project_features_on_project_id')).to be true
        opened_issue = issues.create!(description: 'first', state_id: 1)
        closed_issue = issues.create!(description: 'second', state_id: 2)

        migration.down

        expect(opened_issue.reload.state).to eq('opened')
        expect(closed_issue.reload.state).to eq('closed')
      end
    end

    context 'merge requests' do
      it 'migrates state_id column to old state' do
        opened_merge_request = merge_requests.create!(state_id: 1, target_project_id: project.id, target_branch: 'feature1', source_branch: 'master')
        closed_merge_request = merge_requests.create!(state_id: 2, target_project_id: project.id, target_branch: 'feature2', source_branch: 'master')
        merged_merge_request = merge_requests.create!(state_id: 3, target_project_id: project.id, target_branch: 'feature3', source_branch: 'master')
        locked_merge_request = merge_requests.create!(state_id: 4, target_project_id: project.id, target_branch: 'feature4', source_branch: 'master')

        migration.down

        expect(opened_merge_request.reload.state).to eq('opened')
        expect(closed_merge_request.reload.state).to eq('closed')
        expect(merged_merge_request.reload.state).to eq('merged')
        expect(locked_merge_request.reload.state).to eq('locked')
      end
    end
  end
end
