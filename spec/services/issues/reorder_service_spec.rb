# frozen_string_literal: true

require 'spec_helper'

describe Issues::ReorderService do
  shared_examples 'issues reorder service' do |use_group|
    context 'when reordering issues' do
      let(:issue1)  { create(:issue, project: project) }
      let(:issue2)  { create(:issue, project: project) }
      let(:issue3)  { create(:issue, project: project) }

      it 'returns false with no params' do
        expect(described_class.new(project, user, {}).execute(issue1)).to eq false
      end

      it 'sorts issues' do
        [issue1, issue2, issue3].each do |issue|
          issue.move_to_end && issue.save!
        end

        params = { move_after_id: issue2.id, move_before_id: issue3.id }

        described_class.new(project, user, params).execute(issue1)

        expect(issue1.relative_position).to be_between(issue2.relative_position, issue3.relative_position)
      end

      if use_group
        context 'when ordering in a group issue list' do
          it 'sends the board_group_id parameter' do
            params = { move_after_id: issue2.id, move_before_id: issue3.id, group_full_path: group.full_path }

            match_params = { move_between_ids: [issue2.id, issue3.id], board_group_id: group.id }
            expect(Issues::UpdateService).to receive(:new).with(project, user, match_params).and_return(double(execute: build(:issue)))

            described_class.new(project, user, params).execute(issue1)
          end

          it 'sorts issues' do
            project2 = create(:project, namespace: group)
            issue4   = create(:issue, project: project2)

            [issue1, issue2, issue3, issue4].each do |issue|
              issue.move_to_end && issue.save!
            end

            params = { move_after_id: issue2.id, move_before_id: issue3.id, group_full_path: group.full_path }

            described_class.new(project, user, params).execute(issue4)

            expect(issue4.relative_position).to be_between(issue2.relative_position, issue3.relative_position)
          end
        end
      end
    end
  end

  describe '#execute' do
    context 'when ordering issues in a project' do
      let(:user)    { create(:user) }
      let(:project) { create(:project) }
      let(:parent)  { project }

      before do
        parent.add_developer(user)
      end

      it_behaves_like 'issues reorder service'
    end

    context 'when ordering issues in a group' do
      let(:user)    { create(:user) }
      let(:group)   { create(:group) }
      let(:project) { create(:project, namespace: group) }

      before do
        group.add_developer(user)
      end

      it_behaves_like 'issues reorder service', true
    end
  end
end
