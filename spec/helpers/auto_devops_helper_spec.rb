require 'spec_helper'

describe AutoDevopsHelper do
  set(:project) { create(:project) }
  set(:user) { create(:user) }

  describe '.show_auto_devops_callout?' do
    let(:allowed) { true }

    before do
      allow(helper).to receive(:can?).with(user, :admin_pipeline, project) { allowed }
      allow(helper).to receive(:current_user) { user }

      Feature.get(:auto_devops_banner_disabled).disable
    end

    subject { helper.show_auto_devops_callout?(project) }

    context 'when auto devops is implicitly enabled' do
      it { is_expected.to eq(false) }
    end

    context 'when auto devops is not implicitly enabled' do
      before do
        Gitlab::CurrentSettings.update!(auto_devops_enabled: false)
      end

      it { is_expected.to eq(true) }
    end

    context 'when the banner is disabled by feature flag' do
      before do
        Feature.get(:auto_devops_banner_disabled).enable
      end

      it { is_expected.to be_falsy }
    end

    context 'when dismissed' do
      before do
        helper.request.cookies[:auto_devops_settings_dismissed] = 'true'
      end

      it { is_expected.to eq(false) }
    end

    context 'when user cannot admin project' do
      let(:allowed) { false }

      it { is_expected.to eq(false) }
    end

    context 'when auto devops is enabled system-wide' do
      before do
        stub_application_setting(auto_devops_enabled: true)
      end

      it { is_expected.to eq(false) }
    end

    context 'when auto devops is explicitly enabled for project' do
      before do
        project.create_auto_devops!(enabled: true)
      end

      it { is_expected.to eq(false) }
    end

    context 'when auto devops is explicitly disabled for project' do
      before do
        project.create_auto_devops!(enabled: false)
      end

      it { is_expected.to eq(false) }
    end

    context 'when master contains a .gitlab-ci.yml file' do
      before do
        allow(project.repository).to receive(:gitlab_ci_yml).and_return("script: ['test']")
      end

      it { is_expected.to eq(false) }
    end

    context 'when another service is enabled' do
      before do
        create(:service, project: project, category: :ci, active: true)
      end

      it { is_expected.to eq(false) }
    end
  end

  describe '#auto_devops_badge_for_group' do
    let(:group) { create(:group) }

    subject { helper.auto_devops_badge_for_group(group) }

    context 'when explicitly enabled' do
      let(:group) { create(:group, :auto_devops_enabled) }

      it { is_expected.to eq('group enabled') }
    end

    context 'when explicitly disabled' do
      let(:group) { create(:group, :auto_devops_disabled) }

      it { is_expected.to be_nil }
    end

    context 'when auto devops is implicitly enabled' do
      context 'by instance' do
        before do
          stub_application_setting(auto_devops_enabled: true)
        end

        it { is_expected.to eq('instance enabled') }
      end

      context 'with groups', :nested_groups do
        before do
          group.update(parent: parent)
        end

        context 'when auto devops is enabled on parent' do
          let(:parent) { create(:group, :auto_devops_enabled) }

          it { is_expected.to eq('group enabled') }
        end

        context 'when auto devops is enabled on parent group' do
          let(:parent) { create(:group, parent: create(:group, :auto_devops_enabled)) }

          it { is_expected.to eq('group enabled') }
        end
      end
    end

    context 'when auto devops disabled set on parent group', :nested_groups do
      before do
        parent = create(:group, parent: create(:group, :auto_devops_disabled))
        group.update(parent: parent)
      end

      it { is_expected.to be_nil }
    end
  end

  describe '#auto_devops_badge_for_project' do
    subject { helper.auto_devops_badge_for_project(project) }

    context 'when auto devops is enabled at project level' do
      let(:project) { create(:project, :auto_devops) }

      it { is_expected.to be_nil }
    end

    context 'when auto devops is implicitly enabled' do
      let(:group) { create(:group) }
      let(:project) { create(:project, :repository, namespace: group) }

      context 'by instance' do
        before do
          stub_application_setting(auto_devops_enabled: true)
        end

        it { is_expected.to eq('instance enabled') }
      end

      context 'with groups', :nested_groups do
        before do
          stub_application_setting(auto_devops_enabled: false)
        end

        context 'when auto devops is enabled on group level' do
          let(:group) { create(:group, :auto_devops_enabled) }

          it { is_expected.to eq('group enabled') }
        end

        context 'when auto devops is enabled on parent group' do
          let(:root_parent) { create(:group, :auto_devops_enabled) }
          let(:group) { create(:group, parent: root_parent) }

          it { is_expected.to eq('group enabled') }
        end
      end
    end

    context 'when disabled on parent group' do
      let(:project) { create(:project, :repository, namespace: group) }
      let(:group) { create(:group, :auto_devops_disabled) }

      it { is_expected.to be_nil }

      context 'when grandparent is enabled' do
        let(:root_parent) { create(:group, :auto_devops_enabled) }
        let(:group) { create(:group, :auto_devops_disabled, parent: root_parent) }

        it { is_expected.to be_nil }
      end
    end
  end
end
