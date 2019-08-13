# frozen_string_literal: true

require 'spec_helper'

describe Ci::DeleteStoredArtifactsWorker do
  describe '#perform' do
    let(:worker) { described_class.new }

    subject { worker.perform(artifact_store_path, local) }

    context 'with a local artifact' do
      let(:artifact_store_path) { 'local_file_path' }
      let(:local) { true }
      let(:full_path) { File.join(Gitlab.config.artifacts['storage_path'], 'local_file_path') }

      before do
        allow(File).to receive(:exist?).with(full_path).and_return(true)
      end

      it 'deletes the local artifact' do
        expect(File).to receive(:delete).with(full_path)

        subject
      end
    end

    context 'with a remote artifact' do
      let(:artifact_store_path) { 'remote_file_path' }
      let(:local) { false }
      let(:file_double) { double }

      before do
        stub_artifacts_object_storage

        allow_any_instance_of(Fog::AWS::Storage::Files).to receive(:new).with(key: 'remote_file_path').and_return(file_double)
      end

      it 'deletes the remote artifact' do
        expect(file_double).to receive(:destroy)

        subject
      end
    end
  end
end
