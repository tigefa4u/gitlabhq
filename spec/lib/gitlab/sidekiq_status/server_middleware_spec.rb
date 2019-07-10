require 'spec_helper'

describe Gitlab::SidekiqStatus::ServerMiddleware do
  describe '#call' do
    it 'stops tracking of a job upon completion' do
      expect(Gitlab::SidekiqStatus).to receive(:unset).with('123')

      ret = described_class.new
        .call(double(:worker), { 'jid' => '123' }, double(:queue)) { 10 }

      expect(ret).to eq(10)
    end

    it 'does not track the job in Redis for excluded jobs' do
      expect(Gitlab::SidekiqStatus).not_to receive(:unset)

      described_class.new
        .call(double(:worker), { 'class' => 'BuildQueueWorker', 'jid' => '123' }, double(:queue)) { 10 }
    end
  end
end
