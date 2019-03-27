# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::AcmeClient do
  include AcmeHelpers

  before do
    stub_directory
  end

  describe '#create' do
    subject { described_class.create }

    context 'when admin email is set' do
      let!(:application_setting) { create(:application_setting, admin_notification_email: 'admin@example.com') }

      context 'when account is not yet created' do
        it do
          subject
        end
      end

      context 'when account is already created' do
        it 'returns Acme client' do
          expect(subject).to be_a(Acme::Client)
        end
      end
    end

    context 'when admin email is not set' do
      it 'raises an exeption' do
        expect { subject }.to raise_error('Acme integration is disabled')
      end
    end
  end
end
