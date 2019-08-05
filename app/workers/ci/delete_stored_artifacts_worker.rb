# frozen_string_literal: true

module Ci
  class DeleteStoredArtifactsWorker
    include ApplicationWorker

    def perform(artifact_file_paths)
      artifact_file_paths[::JobArtifactUploader::Store::LOCAL.to_s].each do |file_path|
        delete_local_file(file_path)
      end

      artifact_file_paths[::JobArtifactUploader::Store::REMOTE.to_s].each do |file_path|
        delete_remote_file(file_path)
      end
    end

    private

    def delete_local_file(file_path)
      full_path = File.join(local_directory, file_path)

      File.delete(full_path) if File.exist?(full_path)
    end

    def delete_remote_file(file_path)
      remote_directory.files.new(key: file_path).destroy
    end

    def connection
      Fog::Storage.new(Gitlab.config.artifacts['object_store']['connection'].deep_symbolize_keys)
    end

    def local_directory
      Gitlab.config.artifacts['storage_path']
    end

    def remote_directory
      connection.directories.get(Gitlab.config.artifacts['object_store']['remote_directory'])
    end
  end
end
