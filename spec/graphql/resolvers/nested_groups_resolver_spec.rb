# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::NestedGroupsResolver, feature_category: :groups_and_projects do
  include GraphqlHelpers

  describe '#resolve' do
    let_it_be(:group) { create(:group, name: 'public-group') }
    let_it_be(:private_group) { create(:group, :private, name: 'private-group') }
    let_it_be(:subgroup1) { create(:group, parent: group, name: 'Subgroup') }
    let_it_be(:subgroup2) { create(:group, parent: subgroup1, name: 'Test Subgroup 2') }
    let_it_be(:private_subgroup1) { create(:group, :private, parent: private_group, name: 'Subgroup1') }
    let_it_be(:private_subgroup2) { create(:group, :private, parent: private_subgroup1, name: 'Subgroup2') }
    let_it_be(:user) { create(:user) }

    before_all do
      private_group.add_developer(user)
    end

    shared_examples 'access to all public descendant groups' do
      it 'returns all public descendant groups of the parent group ordered by ASC name' do
        is_expected.to eq([subgroup1, subgroup2])
      end
    end

    shared_examples 'access to all public subgroups' do
      it 'returns all public subgroups of the parent group' do
        is_expected.to contain_exactly(subgroup1)
      end
    end

    shared_examples 'returning empty results' do
      it 'returns empty results' do
        is_expected.to be_empty
      end
    end

    context 'when parent group is public' do
      subject { resolve(described_class, obj: group, args: params, ctx: { current_user: current_user }) }

      context 'when `include_parent_descendants` is false' do
        let(:params) { { include_parent_descendants: false } }

        context 'when user is not logged in' do
          let(:current_user) { nil }

          it_behaves_like 'access to all public subgroups'
        end

        context 'when user is logged in' do
          let(:current_user) { user }

          it_behaves_like 'access to all public subgroups'
        end
      end

      context 'when `include_parent_descendants` is true' do
        let(:params) { { include_parent_descendants: true } }

        context 'when user is not logged in' do
          let(:current_user) { nil }

          it_behaves_like 'access to all public descendant groups'
        end

        context 'when user is logged in' do
          let(:current_user) { user }

          it_behaves_like 'access to all public descendant groups'

          context 'with owned argument set as true' do
            before do
              subgroup1.add_owner(current_user)
              params[:owned] = true
            end

            it 'returns only descendant groups owned by the user' do
              is_expected.to contain_exactly(subgroup1)
            end
          end

          context 'with search argument' do
            it 'returns only descendant groups with matching name or path' do
              params[:search] = 'Test'
              is_expected.to contain_exactly(subgroup2)
            end
          end

          context 'with `ids` argument' do
            it 'filters groups by gid' do
              params[:ids] = [subgroup1.to_global_id.to_s, subgroup2.to_global_id.to_s]
              is_expected.to contain_exactly(subgroup1, subgroup2)
            end
          end
        end
      end
    end

    context 'when parent group is private' do
      subject { resolve(described_class, obj: private_group, args: params, ctx: { current_user: current_user }) }

      context 'when `include_parent_descendants` is true' do
        let(:params) { { include_parent_descendants: true } }

        context 'when user is not logged in' do
          let(:current_user) { nil }

          it_behaves_like 'returning empty results'
        end

        context 'when user is logged in' do
          let(:current_user) { user }

          it 'returns all private descendant groups' do
            is_expected.to contain_exactly(private_subgroup1, private_subgroup2)
          end
        end
      end

      context 'when `include_parent_descendants` is false' do
        let(:params) { { include_parent_descendants: false } }

        context 'when user is not logged in' do
          let(:current_user) { nil }

          it_behaves_like 'returning empty results'
        end

        context 'when user is logged in' do
          let(:current_user) { user }

          it 'returns private subgroups' do
            is_expected.to contain_exactly(private_subgroup1)
          end
        end
      end
    end

    context 'when sorting results' do
      let_it_be(:parent_group) { create(:group, name: 'Parent Group') }
      let_it_be(:group_1) { create(:group, parent: parent_group, name: 'C-group_1', path: 'a-group_1') }
      let_it_be(:group_2) { create(:group, parent: parent_group, name: 'B-group_2', path: 'c-group_2') }
      let_it_be(:group_3) { create(:group, parent: parent_group, name: 'A-group_3', path: 'b-group_3') }

      subject { resolve(described_class, obj: parent_group, args: params, ctx: { current_user: user }) }

      context 'when sorting by name' do
        context 'in ascending order' do
          let(:params) { { sort: 'NAME_ASC' } }

          it 'sorts the groups by name in ascending order' do
            is_expected.to eq(
              [
                group_3,
                group_2,
                group_1
              ]
            )
          end
        end

        context 'in descending order' do
          let(:params) { { sort: 'NAME_DESC' } }

          it 'sorts the groups by name in descending order' do
            is_expected.to eq(
              [
                group_1,
                group_2,
                group_3
              ]
            )
          end
        end
      end

      context 'when sorting by path' do
        context 'in ascending order' do
          let(:params) { { sort: 'PATH_ASC' } }

          it 'sorts the groups by path in ascending order' do
            is_expected.to eq(
              [
                group_1,
                group_3,
                group_2
              ]
            )
          end
        end

        context 'in descending order' do
          let(:params) { { sort: 'PATH_DESC' } }

          it 'sorts the groups by path in descending order' do
            is_expected.to eq(
              [
                group_2,
                group_3,
                group_1
              ]
            )
          end
        end
      end

      context 'when sorting by ID' do
        context 'in ascending order' do
          let(:params) { { sort: 'ID_ASC' } }

          it 'sorts the groups by ID in ascending order' do
            is_expected.to eq(
              [
                group_1,
                group_2,
                group_3
              ]
            )
          end
        end

        context 'in descending order' do
          let(:params) { { sort: 'ID_DESC' } }

          it 'sorts the groups by ID in descending order' do
            is_expected.to eq(
              [
                group_3,
                group_2,
                group_1
              ]
            )
          end
        end
      end
    end
  end
end
