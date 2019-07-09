# frozen_string_literal: true

module Gitlab
  module GitalyClient
    # This is a chokepoint that is meant to help us stop remove all places
    # where production code (app, config, db, lib) touches Git repositories
    # directly.
    class StorageSettings
      extend Gitlab::TemporarilyAllow

      DirectPathAccessError = Class.new(StandardError)
      InvalidConfigurationError = Class.new(StandardError)

      INVALID_STORAGE_MESSAGE = <<~MSG.freeze
        Storage is invalid because it has no `path` key.

        For source installations, update your config/gitlab.yml Refer to gitlab.yml.example for an updated example.
        If you're using the GitLab Development Kit, you can update your configuration running `gdk reconfigure`.
      MSG

      # This class will give easily recognizable NoMethodErrors
      Deprecated = Class.new

      MUTEX = Mutex.new

      DISK_ACCESS_DENIED_FLAG = :deny_disk_access
      ALLOW_KEY = :allow_disk_access
      GITALY_METADATA_FILENAME = '.gitaly-metadata'

      # If your code needs this method then your code needs to be fixed.
      def self.allow_disk_access
        temporarily_allow(ALLOW_KEY) { yield }
      end

      def disk_access_denied?
        return false if self.class.rugged_enabled?
        return false if can_use_disk?

        !self.class.temporarily_allowed?(ALLOW_KEY) && Feature::Gitaly.enabled?(DISK_ACCESS_DENIED_FLAG)
      rescue
        false # Err on the side of caution, don't break gitlab for people
      end

      def self.rugged_enabled?
        Gitlab::Git::RuggedImpl::Repository::FEATURE_FLAGS.any? do |flag|
          Feature.enabled?(flag)
        end
      end

      def initialize(name, storage)
        raise InvalidConfigurationError, "expected a Hash, got a #{storage.class.name}" unless storage.is_a?(Hash)
        raise InvalidConfigurationError, INVALID_STORAGE_MESSAGE unless storage.has_key?('path')

        # Support a nil 'path' field because some of the circuit breaker tests use it.
        @legacy_disk_path = File.expand_path(storage['path'], Rails.root) if storage['path']

        storage['path'] = Deprecated
        @hash = storage
        @name = name
      end

      def gitaly_address
        @hash.fetch(:gitaly_address)
      end

      def legacy_disk_path
        if disk_access_denied?
          raise DirectPathAccessError, "git disk access denied via the gitaly_#{DISK_ACCESS_DENIED_FLAG} feature"
        end

        @legacy_disk_path
      end

      def can_use_disk?
        return @can_use_disk unless @can_use_disk.nil?

        gitaly_filesystem_id = filesystem_id

        @can_use_disk = gitaly_filesystem_id.present? && filesystem_id == filesystem_id_from_disk
      end

      private

      def method_missing(msg, *args, &block)
        @hash.public_send(msg, *args, &block) # rubocop:disable GitlabSecurity/PublicSend
      end

      def filesystem_id
        response = Gitlab::GitalyClient::ServerService.new(@name).info
        storage_status = response.storage_statuses.find { |status| status.storage_name == @name }
        storage_status.filesystem_id
      end

      def filesystem_id_from_disk
        metadata_file = File.read(storage_metadata_file_path)
        metadata_hash = JSON.parse(metadata_file)
        metadata_hash['gitaly_filesystem_id']
      rescue Errno::ENOENT, JSON::ParserError
        nil
      end

      def storage_metadata_file_path
        File.join(@legacy_disk_path, GITALY_METADATA_FILENAME)
      end
    end
  end
end
