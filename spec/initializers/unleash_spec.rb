require 'spec_helper'
require_relative '../../lib/running_web_server'

describe 'Unleash initializer' do
  def load_initializer
    load Rails.root.join('config/initializers/unleash.rb')
  end

  before do
    allow(ENV).to receive(:[]).and_call_original
    Unleash.configuration = nil
  end

  context 'when the web server is unicorn' do
    before do
      allow(RunningWebServer).to receive(:unicorn?).and_return(true)
    end

    it 'sets configuration based on environment variables' do
      allow(ENV).to receive(:[]).with('GITLAB_FEATURE_FLAG_SERVER_URL').and_return('some server url')
      allow(ENV).to receive(:[]).with('GITLAB_FEATURE_FLAG_INSTANCE_ID').and_return('some instance id')

      load_initializer

      expect(Unleash.configuration.url).to eq('some server url')
      expect(Unleash.configuration.instance_id).to eq('some instance id')
      expect(Unleash.configuration.app_name).to eq(Rails.env)
      expect(Unleash.configuration.logger).to be_an_instance_of(Gitlab::UnleashClient::Logger)
    end

    it 'does not set the configuration without a server url' do
      allow(ENV).to receive(:[]).with('GITLAB_FEATURE_FLAG_INSTANCE_ID').and_return('some instance id')

      load_initializer

      expect(Unleash.configuration).to be_nil
    end

    it 'does not set the configuration without an instance id' do
      allow(ENV).to receive(:[]).with('GITLAB_FEATURE_FLAG_SERVER_URL').and_return('some server url')

      load_initializer

      expect(Unleash.configuration).to be_nil
    end
  end

  context 'when the web server is not unicorn' do
    before do
      allow(RunningWebServer).to receive(:unicorn?).and_return(false)
    end

    it 'does not load the config' do
      allow(ENV).to receive(:[]).with('GITLAB_FEATURE_FLAG_SERVER_URL').and_return('some server url')
      allow(ENV).to receive(:[]).with('GITLAB_FEATURE_FLAG_INSTANCE_ID').and_return('some instance id')

      load_initializer

      expect(Unleash.configuration).to be_nil
    end
  end
end
