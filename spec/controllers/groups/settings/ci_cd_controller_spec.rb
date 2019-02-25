require 'spec_helper'

describe Groups::Settings::CiCdController do
  let(:group) { create(:group) }
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  describe 'GET #show' do
    context 'when user is owner' do
      before do
        group.add_owner(user)
      end

      it 'renders show with 200 status code' do
        get :show, params: { group_id: group }

        expect(response).to have_gitlab_http_status(200)
        expect(response).to render_template(:show)
      end
    end

    context 'when user is not owner' do
      before do
        group.add_maintainer(user)
      end

      it 'renders a 404' do
        get :show, params: { group_id: group }

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  describe 'PUT #reset_registration_token' do
    subject { put :reset_registration_token, params: { group_id: group } }

    context 'when user is owner' do
      before do
        group.add_owner(user)
      end

      it 'resets runner registration token' do
        expect { subject }.to change { group.reload.runners_token }
      end

      it 'redirects the user to admin runners page' do
        subject

        expect(response).to redirect_to(group_settings_ci_cd_path)
      end
    end

    context 'when user is not owner' do
      before do
        group.add_maintainer(user)
      end

      it 'renders a 404' do
        subject

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  describe 'PATCH #update_auto_devops' do
    subject do
      patch :update_auto_devops, params: {
        group_id: group,
        group: { auto_devops_enabled: '0' }
      }
    end

    context 'when user does not have enough permission' do
      before do
        group.add_maintainer(user)
      end

      it { is_expected.to have_gitlab_http_status(404) }
    end

    context 'when user has enough privileges' do
      before do
        group.add_owner(user)
      end

      it { is_expected.to redirect_to(group_settings_ci_cd_path) }

      context 'when service execution went wrong' do
        before do
          allow_any_instance_of(Groups::AutoDevopsService).to receive(:execute).and_return(false)
        end

        it { is_expected.to set_flash[:alert].to include('There was a problem enabling Auto DevOps pipeline') }
      end

      context 'when service execution was successful' do
        it { is_expected.to set_flash[:notice].to eq('Auto DevOps pipeline was updated for the group') }
      end
    end
  end
end
