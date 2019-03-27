# frozen_string_literal: true

require 'spec_helper'

describe PagesDomains::CreateAcmeChallengeService do
  let!(:application_setting) { create(:application_setting, admin_notification_email: 'admin@example.com') }
  let(:pages_domain) { create(:pages_domain) }

  it 'creates acme challenge' do
    WebMock.allow_net_connect!
    expect do
      described_class.new(pages_domain).execute
    end.to change { PagesDomainAcmeChallenge.count }.by(1)
  end
end
