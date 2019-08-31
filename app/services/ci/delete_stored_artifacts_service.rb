# frozen_string_literal: true

module Ci
  class DeleteStoredArtifactsService < ::BaseService
    InvalidStoreError = Class.new(StandardError)

    def execute(store_path, file_store)
      case file_store
      when nil, ObjectStorage::Store::LOCAL
        delete_local_file(store_path)
      when ObjectStorage::Store::REMOTE
        delete_remote_file(store_path)
      else
        raise InvalidStoreError
      end
    end

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
