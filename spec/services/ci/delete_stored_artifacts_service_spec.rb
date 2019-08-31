# frozen_string_literal: true

require 'spec_helper'

describe Ci::DeleteStoredArtifactsService do
  describe '#perform' do
    let(:project) { create(:project) }
    let(:service) { described_class.new(project) }

    subject { service.execute(artifact_store_path, file_store) }

    context 'with a local artifact' do
      let(:artifact_store_path) { 'local_file_path' }
      let(:full_path) { File.join(Gitlab.config.artifacts['storage_path'], 'local_file_path') }

      before do
        allow(File).to receive(:exist?).with(full_path).and_return(true)
      end

      context 'when store is local' do
        let(:file_store) { ObjectStorage::Store::LOCAL }

        it 'deletes the local artifact' do
          expect(File).to receive(:delete).with(full_path)

          subject
        end
      end

      context 'when store is nil' do
        let(:file_store) { nil }

        it 'deletes the local artifact' do
          expect(File).to receive(:delete).with(full_path)

          subject
        end
      end
    end

    context 'with a remote artifact' do
      let(:artifact_store_path) { 'remote_file_path' }
      let(:file_store) { ObjectStorage::Store::REMOTE }
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

    context 'with an invalid store' do
      let(:artifact_store_path) { 'file_path' }
      let(:file_store) { 'notavalidstore' }

      it 'raises an error' do
        expect { subject }.to raise_error(described_class::InvalidStoreError)
      end
    end
  end
end
