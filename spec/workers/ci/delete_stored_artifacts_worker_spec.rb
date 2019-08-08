# frozen_string_literal: true

require 'spec_helper'

describe Ci::DeleteStoredArtifactsWorker do
  describe '#perform' do
    let(:worker) { described_class.new }

    subject { worker.perform(file_paths) }

    context 'with a local artifact' do
      let(:path) { File.join(Gitlab.config.artifacts['storage_path'], 'local_file_path') }

      let(:file_paths) do
        {
          ::JobArtifactUploader::Store::LOCAL.to_s => ['local_file_path'],
          ::JobArtifactUploader::Store::REMOTE.to_s => []
        }
      end

      before do
        allow(File).to receive(:exist?).with(path).and_return(true)
      end

      it 'deletes the local artifact' do
        expect(File).to receive(:delete).with(path)

        subject
      end
    end

    context 'with a remote artifact' do
      let(:file_double) { double }

      let(:file_paths) do
        {
          ::JobArtifactUploader::Store::LOCAL.to_s => [],
          ::JobArtifactUploader::Store::REMOTE.to_s => ['remote_file_path']
        }
      end

      before do
        stub_artifacts_object_storage

        allow_any_instance_of(Fog::AWS::Storage::Files).to receive(:new).with(key: 'remote_file_path').and_return(file_double)
      end

      it 'deletes the remote artifact' do
        expect(file_double).to receive(:destroy)

        subject
      end
    end

    context 'with both local and remote artifacts' do
      let(:file_paths) do
        {
          ::JobArtifactUploader::Store::LOCAL.to_s => ['local_file_path'],
          ::JobArtifactUploader::Store::REMOTE.to_s => ['remote_file_path']
        }
      end

      it 'calls correct delete methods' do
        expect(worker).to receive(:delete_local_file).with('local_file_path').once
        expect(worker).to receive(:delete_remote_file).with('remote_file_path').once

        subject
      end
    end
  end
end
