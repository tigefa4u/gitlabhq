# frozen_string_literal: true

require 'spec_helper'

describe Ci::DeleteStoredArtifactsWorker do
  describe '#perform' do
    let(:project) { create(:project) }
    let(:worker) { described_class.new }
    let(:store_path) { 'file_path' }
    let(:local_store) { true }
    let(:size) { 10 }

    subject { worker.perform(project.id, store_path, local_store, size) }

    before do
      allow(UpdateProjectStatistics).to receive(:update_project_statistics!)
      allow(Ci::DeleteStoredArtifactsService).to receive_message_chain(:new, :execute)
    end

    it 'calls the delete service' do
      expect(Ci::DeleteStoredArtifactsService).to receive_message_chain(:new, :execute).with(store_path, local_store)

      subject
    end

    it 'updates the project statistics' do
      expect(UpdateProjectStatistics).to receive(:update_project_statistics!).with(project, :build_artifacts_size, -size)

      subject
    end
  end
end
