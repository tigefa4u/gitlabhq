require 'spec_helper'

describe Gitlab::SidekiqStatus::ClientMiddleware do
  describe '#call' do
    it 'tracks the job in Redis' do
      expect(Gitlab::SidekiqStatus).to receive(:set).with('123', Gitlab::SidekiqStatus::DEFAULT_EXPIRATION)

      described_class.new
        .call('Foo', { 'jid' => '123' }, double(:queue), double(:pool)) { nil }
    end

    it 'does not track the job in Redis for excluded jobs' do
      expect(Gitlab::SidekiqStatus).not_to receive(:set)

      described_class.new
        .call('BuildQueueWorker', { 'class' => 'BuildQueueWorker', 'jid' => '123' }, double(:queue), double(:pool)) { nil }
    end
  end
end
