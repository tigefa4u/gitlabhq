require 'spec_helper'

describe FeatureFlagClient do
  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(Unleash::Client).to receive(:new).and_return("fake client instance")
    described_class.instance_variable_set(:@client, nil)
  end

  describe '.enabled?' do
    it 'returns false' do
      expect(described_class.enabled?(:feature_flag)).to eq(false)
    end

    it 'sets configuration based on environment variables' do
      allow(ENV).to receive(:[]).with('GITLAB_FEATURE_FLAG_SERVER_URL').and_return('some server url')
      allow(ENV).to receive(:[]).with('GITLAB_FEATURE_FLAG_INSTANCE_ID').and_return('some instance id')
      expect(Unleash::Client).to receive(:new).with(
        url: 'some server url',
        instance_id: 'some instance id',
        app_name: Rails.env
      )

      described_class.enabled?(:my_feature)
    end

    it 'is a singleton' do
      allow(ENV).to receive(:[]).with('GITLAB_FEATURE_FLAG_SERVER_URL').and_return('some server url')
      allow(ENV).to receive(:[]).with('GITLAB_FEATURE_FLAG_INSTANCE_ID').and_return('some instance id')
      expect(Unleash::Client).to receive(:new).with(
        url: 'some server url',
        instance_id: 'some instance id',
        app_name: Rails.env
      ).once

      described_class.enabled?(:my_feature)
      described_class.enabled?(:my_feature)
    end

    it 'does not set the configuration without a server url' do
      allow(ENV).to receive(:[]).with('GITLAB_FEATURE_FLAG_INSTANCE_ID').and_return('some instance id')
      expect(Unleash::Client).not_to receive(:new)

      described_class.enabled?(:my_feature)
    end

    it 'does not set the configuration without an instance id' do
      allow(ENV).to receive(:[]).with('GITLAB_FEATURE_FLAG_SERVER_URL').and_return('some server url')
      expect(Unleash::Client).not_to receive(:new)

      described_class.enabled?(:my_feature)
    end
  end
end
