# frozen_string_literal: true

require 'spec_helper'

describe Git::ExternalMergeRequestPushService do
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }
  let(:oldrev) { Gitlab::Git::BLANK_SHA }
  let(:newrev) { '8a2a6eb295bb170b34c24c76c49ed0e9b2eaf34b' }
  let(:ref) { 'ref/pull/123' }

  let(:service) { described_class.new(project, user, oldrev: oldrev, newrev: newrev, ref: ref) }

  describe 'Hooks' do
    context 'run on an external merge request like GitHub pull request' do
      it 'delegates to Git::ExternalMergeRequestHooksService' do
        expect_next_instance_of(::Git::ExternalMergeRequestHooksService) do |hooks_service|
          expect(hooks_service.project).to eq(service.project)
          expect(hooks_service.current_user).to eq(service.current_user)
          expect(hooks_service.params).to eq(service.params)

          expect(hooks_service).to receive(:execute)
        end

        service.execute
      end
    end

    context 'run on a branch' do
      let(:ref) { 'refs/heads/master' }

      it 'does nothing' do
        expect(::Git::ExternalMergeRequestHooksService).not_to receive(:new)

        service.execute
      end
    end

    context 'run on a tag' do
      let(:ref) { 'refs/tags/v1.1.0' }

      it 'does nothing' do
        expect(::Git::ExternalMergeRequestHooksService).not_to receive(:new)

        service.execute
      end
    end
  end
end
