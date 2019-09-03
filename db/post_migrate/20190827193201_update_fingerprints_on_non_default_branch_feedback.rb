# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class UpdateFingerprintsOnNonDefaultBranchFeedback < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    Feedback.where_might_need_update.find_in_batches(batch_size: 500) do |feedback_batch|
      feedback_batch.each do |feedback|
        if feedback.needs_update?
          begin
            feedback.update_fingerprint!
          rescue ActiveRecord::RecordNotUnique
            feedback.destroy
          end
        end
      end
    end
  end

  def down
    # We don't want to re-break the fingerprints if a user needs to rollback
    # any number of migrations that include this one.
  end

  class Artifact < ActiveRecord::Base
    self.table_name = 'ci_job_artifacts'

    mount_uploader :file, JobArtifactUploader

    enum file_location: {
      legacy_path: 1,
      hashed_path: 2
    }

    enum file_type: {
      dependency_scanning: 6,
      container_scanning: 7
    }
  end
  private_constant :Artifact

  class Build < ActiveRecord::Base
    self.table_name = 'ci_builds'

    has_many :artifacts, foreign_key: :job_id
  end
  private_constant :Build

  class Occurrence < ActiveRecord::Base
    self.table_name = 'vulnerability_occurrences'
  end
  private_constant :Occurrence

  class OccurrencePipeline < ActiveRecord::Base
    self.table_name = 'vulnerability_occurrence_pipelines'

    belongs_to :occurrence
  end
  private_constant :OccurrencePipeline

  class Pipeline < ActiveRecord::Base
    self.table_name = 'ci_pipelines'

    has_many :builds, foreign_key: :commit_id
    has_many :artifacts, through: :builds
    has_many :occurrence_pipelines
    has_many :occurrences, through: :occurrence_pipelines
  end
  private_constant :Pipeline

  class Feedback < ActiveRecord::Base
    self.table_name = 'vulnerability_feedback'

    belongs_to :pipeline
    has_many :artifacts, through: :pipeline
    has_many :occurrences, through: :pipeline

    enum category: { dependency_scanning: 1, container_scanning: 2 }

    # Feedback that might need update are feedback on vulnerabilities reported
    # by container scanning or dependency scanning jobs run on any branch except
    # the default branch
    def self.where_might_need_update
      left_outer_joins(:occurrences)
        .joins(:artifacts)
        .includes(:artifacts)
        .where(ci_job_artifacts: { file_type: [6, 7] })
        .where('vulnerability_occurrences IS NULL')
    end

    def update_fingerprint!
      update(project_fingerprint: new_fingerprint)
    end

    def needs_update?
      vulnerability.present?
    end

    private

    def vulnerability
      @vulnerability ||= report['vulnerabilities'].find do |vuln|
        old_fingerprint(vuln) == project_fingerprint
      end
    end

    def report
      @report ||= artifact.present? ? JSON.parse(artifact.file.read) : { 'vulnerabilities' => [] }
    end

    def artifact
      @artifact ||= artifacts.find { |artifact| artifact.file_type == category }
    end

    def old_fingerprint(vuln)
      if dependency_scanning?
        Digest::SHA1.hexdigest(vuln['message'])
      elsif container_scanning?
        Digest::SHA1.hexdigest(
          "#{vuln['namespace']}:#{vuln['vulnerability']}" \
          ":#{vuln['featurename']}:#{vuln['featureversion']}"
        )
      end
    end

    def new_fingerprint
      if dependency_scanning?
        Digest::SHA1.hexdigest(vulnerability['cve'])
      elsif container_scanning?
        Digest::SHA1.hexdigest(vulnerability['vulnerability'])
      end
    end
  end
  private_constant :Feedback

  # EVERYTHING BELOW THIS COMMENT IS A DIRECT COPY FROM THE ORIGINAL GITLAB CLASSES
  # (except ObjectStorage, from which I removed some unneeded submodules)

  require 'carrierwave/storage/fog'
  require 'fog/aws'
  require 'sidekiq/api'
  require 'active_support/core_ext/hash/keys'
  require 'active_support/core_ext/module/delegation'

  Sidekiq::Worker.extend ActiveSupport::Concern

  class JobArtifactUploader < GitlabUploader
    extend Workhorse::UploadPath
    include ObjectStorage::Concern

    ObjectNotReadyError = Class.new(StandardError)
    UnknownFileLocationError = Class.new(StandardError)

    storage_options Gitlab.config.artifacts

    alias_method :upload, :model

    def cached_size
      return model.size if model.size.present? && !model.file_changed?

      size
    end

    def store_dir
      dynamic_segment
    end

    private

    def dynamic_segment
      raise ObjectNotReadyError, 'JobArtifact is not ready' unless model.id

      if model.hashed_path?
        hashed_path
      elsif model.legacy_path?
        legacy_path
      else
        raise UnknownFileLocationError
      end
    end

    def hashed_path
      File.join(disk_hash[0..1], disk_hash[2..3], disk_hash,
                model.created_at.utc.strftime('%Y_%m_%d'), model.job_id.to_s, model.id.to_s)
    end

    def legacy_path
      File.join(model.created_at.utc.strftime('%Y_%m'), model.project_id.to_s, model.job_id.to_s)
    end

    def disk_hash
      @disk_hash ||= Digest::SHA2.hexdigest(model.project_id.to_s)
    end
  end

  module Workhorse
    module UploadPath
      def workhorse_upload_path
        File.join(root, base_dir, 'tmp/uploads')
      end
    end
  end

  module ObjectStorage
    RemoteStoreError = Class.new(StandardError)
    UnknownStoreError = Class.new(StandardError)
    ObjectStorageUnavailable = Class.new(StandardError)

    class ExclusiveLeaseTaken < StandardError
      def initialize(lease_key)
        @lease_key = lease_key
      end

      def message
        *lease_key_group, _ = *@lease_key.split(":")
        "Exclusive lease for #{lease_key_group.join(':')} is already taken."
      end
    end

    TMP_UPLOAD_PATH = 'tmp/uploads'.freeze

    module Store
      LOCAL = 1
      REMOTE = 2
    end

    module Concern
      extend ActiveSupport::Concern

      included do |base|
        base.include(ObjectStorage)

        after :migrate, :delete_migrated_file
      end

      class_methods do
        def object_store_options
          options.object_store
        end

        def object_store_enabled?
          object_store_options.enabled
        end

        def direct_upload_enabled?
          object_store_options&.direct_upload
        end

        def background_upload_enabled?
          object_store_options.background_upload
        end

        def proxy_download_enabled?
          object_store_options.proxy_download
        end

        def direct_download_enabled?
          !proxy_download_enabled?
        end

        def object_store_credentials
          object_store_options.connection.to_hash.deep_symbolize_keys
        end

        def remote_store_path
          object_store_options.remote_directory
        end

        def serialization_column(model_class, mount_point)
          model_class.uploader_options.dig(mount_point, :mount_on) || mount_point
        end

        def workhorse_authorize(has_length:, maximum_size: nil)
          {
            RemoteObject: workhorse_remote_upload_options(has_length: has_length, maximum_size: maximum_size),
            TempPath: workhorse_local_upload_path
          }.compact
        end

        def workhorse_local_upload_path
          File.join(self.root, TMP_UPLOAD_PATH)
        end

        def workhorse_remote_upload_options(has_length:, maximum_size: nil)
          return unless self.object_store_enabled?
          return unless self.direct_upload_enabled?

          id = [CarrierWave.generate_cache_id, SecureRandom.hex].join('-')
          upload_path = File.join(TMP_UPLOAD_PATH, id)
          direct_upload = ObjectStorage::DirectUpload.new(self.object_store_credentials, remote_store_path, upload_path,
                                                          has_length: has_length, maximum_size: maximum_size)

          direct_upload.to_hash.merge(ID: id)
        end
      end

      # allow to configure and overwrite the filename
      def filename
        @filename || super || file&.filename # rubocop:disable Gitlab/ModuleWithInstanceVariables
      end

      def filename=(filename)
        @filename = filename # rubocop:disable Gitlab/ModuleWithInstanceVariables
      end

      def file_storage?
        storage.is_a?(CarrierWave::Storage::File)
      end

      def file_cache_storage?
        cache_storage.is_a?(CarrierWave::Storage::File)
      end

      def object_store
        # We use Store::LOCAL as null value indicates the local storage
        @object_store ||= model.try(store_serialization_column) || Store::LOCAL
      end

      # rubocop:disable Gitlab/ModuleWithInstanceVariables
      def object_store=(value)
        @object_store = value || Store::LOCAL
        @storage = storage_for(object_store)
      end
      # rubocop:enable Gitlab/ModuleWithInstanceVariables

      # Return true if the current file is part or the model (i.e. is mounted in the model)
      #
      def persist_object_store?
        model.respond_to?(:"#{store_serialization_column}=")
      end

      # Save the current @object_store to the model <mounted_as>_store column
      def persist_object_store!
        return unless persist_object_store?

        updated = model.update_column(store_serialization_column, object_store)
        raise 'Failed to update object store' unless updated
      end

      def use_file(&blk)
        with_exclusive_lease do
          unsafe_use_file(&blk)
        end
      end

      #
      # Move the file to another store
      #
      #   new_store: Enum (Store::LOCAL, Store::REMOTE)
      #
      def migrate!(new_store)
        with_exclusive_lease do
          unsafe_migrate!(new_store)
        end
      end

      def schedule_background_upload(*args)
        return unless schedule_background_upload?

        ObjectStorage::BackgroundMoveWorker.perform_async(self.class.name,
                                                          model.class.name,
                                                          mounted_as,
                                                          model.id)
      end

      def fog_directory
        self.class.remote_store_path
      end

      def fog_credentials
        self.class.object_store_credentials
      end

      # Set ACL of uploaded objects to not-public (fog-aws)[1] or no ACL at all
      # (fog-google).  Value is ignored by other supported backends (fog-aliyun,
      # fog-openstack, fog-rackspace)
      # [1]: https://github.com/fog/fog-aws/blob/daa50bb3717a462baf4d04d0e0cbfc18baacb541/lib/fog/aws/models/storage/file.rb#L152-L159
      def fog_public
        nil
      end

      def delete_migrated_file(migrated_file)
        migrated_file.delete
      end

      def exists?
        file.present?
      end

      def store_dir(store = nil)
        store_dirs[store || object_store]
      end

      def store_dirs
        {
          Store::LOCAL => File.join(base_dir, dynamic_segment),
          Store::REMOTE => File.join(dynamic_segment)
        }
      end

      # Returns all the possible paths for an upload.
      # the `upload.path` is a lookup parameter, and it may change
      # depending on the `store` param.
      def upload_paths(identifier)
        store_dirs.map { |store, path| File.join(path, identifier) }
      end

      def cache!(new_file = sanitized_file)
        # We intercept ::UploadedFile which might be stored on remote storage
        # We use that for "accelerated" uploads, where we store result on remote storage
        if new_file.is_a?(::UploadedFile) && new_file.remote_id
          return cache_remote_file!(new_file.remote_id, new_file.original_filename)
        end

        super
      end

      def store!(new_file = nil)
        # when direct upload is enabled, always store on remote storage
        if self.class.object_store_enabled? && self.class.direct_upload_enabled?
          self.object_store = Store::REMOTE
        end

        super
      end

      def exclusive_lease_key
        "object_storage_migrate:#{model.class}:#{model.id}"
      end

      private

      def schedule_background_upload?
        self.class.object_store_enabled? &&
          self.class.background_upload_enabled? &&
          self.file_storage?
      end

      def cache_remote_file!(remote_object_id, original_filename)
        file_path = File.join(TMP_UPLOAD_PATH, remote_object_id)
        file_path = Pathname.new(file_path).cleanpath.to_s
        raise RemoteStoreError, 'Bad file path' unless file_path.start_with?(TMP_UPLOAD_PATH + '/')

        # TODO:
        # This should be changed to make use of `tmp/cache` mechanism
        # instead of using custom upload directory,
        # using tmp/cache makes this implementation way easier than it is today
        CarrierWave::Storage::Fog::File.new(self, storage_for(Store::REMOTE), file_path).tap do |file|
          raise RemoteStoreError, 'Missing file' unless file.exists?

          # Remote stored file, we force to store on remote storage
          self.object_store = Store::REMOTE

          # TODO:
          # We store file internally and force it to be considered as `cached`
          # This makes CarrierWave to store file in permament location (copy/delete)
          # once this object is saved, but not sooner
          @cache_id = "force-to-use-cache" # rubocop:disable Gitlab/ModuleWithInstanceVariables
          @file = file # rubocop:disable Gitlab/ModuleWithInstanceVariables
          @filename = original_filename # rubocop:disable Gitlab/ModuleWithInstanceVariables
        end
      end

      # this is a hack around CarrierWave. The #migrate method needs to be
      # able to force the current file to the migrated file upon success.
      def file=(file)
        @file = file # rubocop:disable Gitlab/ModuleWithInstanceVariables
      end

      def serialization_column
        self.class.serialization_column(model.class, mounted_as)
      end

      # Returns the column where the 'store' is saved
      #   defaults to 'store'
      def store_serialization_column
        [serialization_column, 'store'].compact.join('_').to_sym
      end

      def storage
        @storage ||= storage_for(object_store)
      end

      def storage_for(store)
        case store
        when Store::REMOTE
          raise 'Object Storage is not enabled' unless self.class.object_store_enabled?

          CarrierWave::Storage::Fog.new(self)
        when Store::LOCAL
          CarrierWave::Storage::File.new(self)
        else
          raise UnknownStoreError
        end
      end

      def with_exclusive_lease
        lease_key = exclusive_lease_key
        uuid = Gitlab::ExclusiveLease.new(lease_key, timeout: 1.hour.to_i).try_obtain
        raise ExclusiveLeaseTaken.new(lease_key) unless uuid

        yield uuid
      ensure
        Gitlab::ExclusiveLease.cancel(lease_key, uuid)
      end

      #
      # Move the file to another store
      #
      #   new_store: Enum (Store::LOCAL, Store::REMOTE)
      #
      def unsafe_migrate!(new_store)
        return unless object_store != new_store
        return unless file

        new_file = nil
        file_to_delete = file
        from_object_store = object_store
        self.object_store = new_store # changes the storage and file

        cache_stored_file! if file_storage?

        with_callbacks(:migrate, file_to_delete) do
          with_callbacks(:store, file_to_delete) do # for #store_versions!
            new_file = storage.store!(file)
            persist_object_store!
            self.file = new_file
          end
        end

        file
      rescue => e
        # in case of failure delete new file
        new_file.delete unless new_file.nil?
        # revert back to the old file
        self.object_store = from_object_store
        self.file = file_to_delete
        raise e
      end
    end

    def unsafe_use_file
      if file_storage?
        return yield path
      end

      begin
        cache_stored_file!
        yield cache_path
      ensure
        FileUtils.rm_f(cache_path)
        cache_storage.delete_dir!(cache_path(nil))
      end
    end
  end

  class GitlabUploader < CarrierWave::Uploader::Base
    class_attribute :options

    class << self
      # DSL setter
      def storage_options(options)
        self.options = options
      end

      def root
        options.storage_path
      end

      # represent the directory namespacing at the class level
      def base_dir
        options.fetch('base_dir', '')
      end

      def file_storage?
        storage == CarrierWave::Storage::File
      end

      def absolute_path(upload_record)
        File.join(root, upload_record.path)
      end
    end

    storage_options Gitlab.config.uploads

    delegate :base_dir, :file_storage?, to: :class

    def initialize(model, mounted_as = nil, **uploader_context)
      super(model, mounted_as)
    end

    def file_cache_storage?
      cache_storage.is_a?(CarrierWave::Storage::File)
    end

    def move_to_cache
      file_storage?
    end

    def move_to_store
      file_storage?
    end

    def exists?
      file.present?
    end

    def cache_dir
      File.join(root, base_dir, 'tmp/cache')
    end

    def work_dir
      File.join(root, base_dir, 'tmp/work')
    end

    def filename
      super || file&.filename
    end

    def relative_path
      return path if pathname.relative?

      pathname.relative_path_from(Pathname.new(root))
    end

    def model_valid?
      !!model
    end

    def local_url
      File.join('/', self.class.base_dir, dynamic_segment, filename)
    end

    def cached_size
      size
    end

    def open
      stream =
        if file_storage?
          File.open(path, "rb") if path
        else
          ::Gitlab::HttpIO.new(url, cached_size) if url
        end

      return unless stream
      return stream unless block_given?

      begin
        yield(stream)
      ensure
        stream.close
      end
    end

    private

    # Designed to be overridden by child uploaders that have a dynamic path
    # segment -- that is, a path that changes based on mutable attributes of its
    # associated model
    #
    # For example, `FileUploader` builds the storage path based on the associated
    # project model's `path_with_namespace` value, which can change when the
    # project or its containing namespace is moved or renamed.
    def dynamic_segment
      raise(NotImplementedError)
    end

    # To prevent files from moving across filesystems, override the default
    # implementation:
    # http://github.com/carrierwaveuploader/carrierwave/blob/v1.0.0/lib/carrierwave/uploader/cache.rb#L181-L183
    def workfile_path(for_file = original_filename)
      # To be safe, keep this directory outside of the the cache directory
      # because calling CarrierWave.clean_cache_files! will remove any files in
      # the cache directory.
      File.join(work_dir, cache_id, version_name.to_s, for_file)
    end

    def pathname
      @pathname ||= Pathname.new(path)
    end
  end

  module Gitlab
    class HttpIO
      BUFFER_SIZE = 128.kilobytes

      InvalidURLError = Class.new(StandardError)
      FailedToGetChunkError = Class.new(StandardError)

      attr_reader :uri, :size
      attr_reader :tell
      attr_reader :chunk, :chunk_range

      alias_method :pos, :tell

      def initialize(url, size)
        raise InvalidURLError unless ::Gitlab::UrlSanitizer.valid?(url)

        @uri = URI(url)
        @size = size
        @tell = 0
      end

      def close
        # no-op
      end

      def binmode
        # no-op
      end

      def binmode?
        true
      end

      def path
        nil
      end

      def url
        @uri.to_s
      end

      def seek(pos, where = IO::SEEK_SET)
        new_pos =
          case where
          when IO::SEEK_END
            size + pos
          when IO::SEEK_SET
            pos
          when IO::SEEK_CUR
            tell + pos
          else
            -1
          end

        raise 'new position is outside of file' if new_pos < 0 || new_pos > size

        @tell = new_pos
      end

      def eof?
        tell == size
      end

      def each_line
        until eof?
          line = readline
          break if line.nil?

          yield(line)
        end
      end

      def read(length = nil, outbuf = nil)
        out = []

        length ||= size - tell

        until length <= 0 || eof?
          data = get_chunk
          break if data.empty?

          chunk_bytes = [BUFFER_SIZE - chunk_offset, length].min
          data_slice = data.byteslice(0, chunk_bytes)

          out << data_slice
          @tell += data_slice.bytesize
          length -= data_slice.bytesize
        end

        out = out.join

        # If outbuf is passed, we put the output into the buffer. This supports IO.copy_stream functionality
        if outbuf
          outbuf.replace(out)
        end

        out
      end

      def readline
        out = []

        until eof?
          data = get_chunk
          new_line = data.index("\n")

          if !new_line.nil?
            out << data[0..new_line]
            @tell += new_line + 1
            break
          else
            out << data
            @tell += data.bytesize
          end
        end

        out.join
      end

      def write(data)
        raise NotImplementedError
      end

      def truncate(offset)
        raise NotImplementedError
      end

      def flush
        raise NotImplementedError
      end

      def present?
        true
      end

      private

      ##
      # The below methods are not implemented in IO class
      #
      def in_range?
        @chunk_range&.include?(tell)
      end

      def get_chunk
        unless in_range?
          response = Net::HTTP.start(uri.hostname, uri.port, proxy_from_env: true, use_ssl: uri.scheme == 'https') do |http|
            http.request(request)
          end

          raise FailedToGetChunkError unless response.code == '200' || response.code == '206'

          @chunk = response.body.force_encoding(Encoding::BINARY)
          @chunk_range = response.content_range

          ##
          # Note: If provider does not return content_range, then we set it as we requested
          # Provider: minio
          # - When the file size is larger than requested Content-range, the Content-range is included in responses with Net::HTTPPartialContent 206
          # - When the file size is smaller than requested Content-range, the Content-range is included in responses with Net::HTTPPartialContent 206
          # Provider: AWS
          # - When the file size is larger than requested Content-range, the Content-range is included in responses with Net::HTTPPartialContent 206
          # - When the file size is smaller than requested Content-range, the Content-range is included in responses with Net::HTTPPartialContent 206
          # Provider: GCS
          # - When the file size is larger than requested Content-range, the Content-range is included in responses with Net::HTTPPartialContent 206
          # - When the file size is smaller than requested Content-range, the Content-range is included in responses with Net::HTTPOK 200
          @chunk_range ||= (chunk_start...(chunk_start + @chunk.bytesize))
        end

        @chunk[chunk_offset..BUFFER_SIZE]
      end

      def request
        Net::HTTP::Get.new(uri).tap do |request|
          request.set_range(chunk_start, BUFFER_SIZE)
        end
      end

      def chunk_offset
        tell % BUFFER_SIZE
      end

      def chunk_start
        (tell / BUFFER_SIZE) * BUFFER_SIZE
      end

      def chunk_end
        [chunk_start + BUFFER_SIZE, size].min
      end
    end
  end

  module Gitlab
    class UrlSanitizer
      ALLOWED_SCHEMES = %w[http https ssh git].freeze

      def self.sanitize(content)
        regexp = URI::DEFAULT_PARSER.make_regexp(ALLOWED_SCHEMES)

        content.gsub(regexp) { |url| new(url).masked_url }
      rescue Addressable::URI::InvalidURIError
        content.gsub(regexp, '')
      end

      def self.valid?(url)
        return false unless url.present?
        return false unless url.is_a?(String)

        uri = Addressable::URI.parse(url.strip)

        ALLOWED_SCHEMES.include?(uri.scheme)
      rescue Addressable::URI::InvalidURIError
        false
      end

      def initialize(url, credentials: nil)
        %i[user password].each do |symbol|
          credentials[symbol] = credentials[symbol].presence if credentials&.key?(symbol)
        end

        @credentials = credentials
        @url = parse_url(url)
      end

      def sanitized_url
        @sanitized_url ||= safe_url.to_s
      end

      def masked_url
        url = @url.dup
        url.password = "*****" if url.password.present?
        url.user = "*****" if url.user.present?
        url.to_s
      end

      def credentials
        @credentials ||= { user: @url.user.presence, password: @url.password.presence }
      end

      def user
        credentials[:user]
      end

      def full_url
        @full_url ||= generate_full_url.to_s
      end

      private

      def parse_url(url)
        url             = url.to_s.strip
        match           = url.match(%r{\A(?:git|ssh|http(?:s?))\://(?:(.+)(?:@))?(.+)})
        raw_credentials = match[1] if match

        if raw_credentials.present?
          url.sub!("#{raw_credentials}@", '')

          user, _, password = raw_credentials.partition(':')
          @credentials ||= { user: user.presence, password: password.presence }
        end

        url = Addressable::URI.parse(url)
        url.password = password if password.present?
        url.user = user if user.present?
        url
      end

      def generate_full_url
        return @url unless valid_credentials?

        @url.dup.tap do |generated|
          generated.password = encode_percent(credentials[:password]) if credentials[:password].present?
          generated.user = encode_percent(credentials[:user]) if credentials[:user].present?
        end
      end

      def safe_url
        safe_url = @url.dup
        safe_url.password = nil
        safe_url.user = nil
        safe_url
      end

      def valid_credentials?
        credentials && credentials.is_a?(Hash) && credentials.any?
      end

      def encode_percent(string)
        # CGI.escape converts spaces to +, but this doesn't work for git clone
        CGI.escape(string).gsub('+', '%20')
      end
    end
  end

  module Gitlab
    module Utils
      module StrongMemoize
        # Instead of writing patterns like this:
        #
        #     def trigger_from_token
        #       return @trigger if defined?(@trigger)
        #
        #       @trigger = Ci::Trigger.find_by_token(params[:token].to_s)
        #     end
        #
        # We could write it like:
        #
        #     include Gitlab::Utils::StrongMemoize
        #
        #     def trigger_from_token
        #       strong_memoize(:trigger) do
        #         Ci::Trigger.find_by_token(params[:token].to_s)
        #       end
        #     end
        #
        def strong_memoize(name)
          if instance_variable_defined?(ivar(name))
            instance_variable_get(ivar(name))
          else
            instance_variable_set(ivar(name), yield)
          end
        end

        def clear_memoization(name)
          remove_instance_variable(ivar(name)) if instance_variable_defined?(ivar(name))
        end

        private

        def ivar(name)
          "@#{name}"
        end
      end
    end
  end

  module ObjectStorage
    #
    # The DirectUpload c;ass generates a set of presigned URLs
    # that can be used to upload data to object storage from untrusted component: Workhorse, Runner?
    #
    # For Google it assumes that the platform supports variable Content-Length.
    #
    # For AWS it initiates Multipart Upload and presignes a set of part uploads.
    #   Class calculates the best part size to be able to upload up to asked maximum size.
    #   The number of generated parts will never go above 100,
    #   but we will always try to reduce amount of generated parts.
    #   The part size is rounded-up to 5MB.
    #
    class DirectUpload
      include Gitlab::Utils::StrongMemoize

      TIMEOUT = 4.hours
      EXPIRE_OFFSET = 15.minutes

      MAXIMUM_MULTIPART_PARTS = 100
      MINIMUM_MULTIPART_SIZE = 5.megabytes

      attr_reader :credentials, :bucket_name, :object_name
      attr_reader :has_length, :maximum_size

      def initialize(credentials, bucket_name, object_name, has_length:, maximum_size: nil)
        unless has_length
          raise ArgumentError, 'maximum_size has to be specified if length is unknown' unless maximum_size
        end

        @credentials = credentials
        @bucket_name = bucket_name
        @object_name = object_name
        @has_length = has_length
        @maximum_size = maximum_size
      end

      def to_hash
        {
          Timeout: TIMEOUT,
          GetURL: get_url,
          StoreURL: store_url,
          DeleteURL: delete_url,
          MultipartUpload: multipart_upload_hash,
          CustomPutHeaders: true,
          PutHeaders: upload_options
        }.compact
      end

      def multipart_upload_hash
        return unless requires_multipart_upload?

        {
          PartSize: rounded_multipart_part_size,
          PartURLs: multipart_part_urls,
          CompleteURL: multipart_complete_url,
          AbortURL: multipart_abort_url
        }
      end

      def provider
        credentials[:provider].to_s
      end

      # Implements https://docs.aws.amazon.com/AmazonS3/latest/API/RESTObjectGET.html
      def get_url
        connection.get_object_url(bucket_name, object_name, expire_at)
      end

      # Implements https://docs.aws.amazon.com/AmazonS3/latest/API/RESTObjectDELETE.html
      def delete_url
        connection.delete_object_url(bucket_name, object_name, expire_at)
      end

      # Implements https://docs.aws.amazon.com/AmazonS3/latest/API/RESTObjectPUT.html
      def store_url
        connection.put_object_url(bucket_name, object_name, expire_at, upload_options)
      end

      def multipart_part_urls
        Array.new(number_of_multipart_parts) do |part_index|
          multipart_part_upload_url(part_index + 1)
        end
      end

      # Implements https://docs.aws.amazon.com/AmazonS3/latest/API/mpUploadUploadPart.html
      def multipart_part_upload_url(part_number)
        connection.signed_url({
          method: 'PUT',
          bucket_name: bucket_name,
          object_name: object_name,
          query: { 'uploadId' => upload_id, 'partNumber' => part_number },
          headers: upload_options
        }, expire_at)
      end

      # Implements https://docs.aws.amazon.com/AmazonS3/latest/API/mpUploadComplete.html
      def multipart_complete_url
        connection.signed_url({
          method: 'POST',
          bucket_name: bucket_name,
          object_name: object_name,
          query: { 'uploadId' => upload_id },
          headers: { 'Content-Type' => 'application/xml' }
        }, expire_at)
      end

      # Implements https://docs.aws.amazon.com/AmazonS3/latest/API/mpUploadAbort.html
      def multipart_abort_url
        connection.signed_url({
          method: 'DELETE',
          bucket_name: bucket_name,
          object_name: object_name,
          query: { 'uploadId' => upload_id }
        }, expire_at)
      end

      private

      def rounded_multipart_part_size
        # round multipart_part_size up to minimum_mulitpart_size
        (multipart_part_size + MINIMUM_MULTIPART_SIZE - 1) / MINIMUM_MULTIPART_SIZE * MINIMUM_MULTIPART_SIZE
      end

      def multipart_part_size
        maximum_size / number_of_multipart_parts
      end

      def number_of_multipart_parts
        [
          # round maximum_size up to minimum_mulitpart_size
          (maximum_size + MINIMUM_MULTIPART_SIZE - 1) / MINIMUM_MULTIPART_SIZE,
          MAXIMUM_MULTIPART_PARTS
        ].min
      end

      def aws?
        provider == 'AWS'
      end

      def requires_multipart_upload?
        aws? && !has_length
      end

      def upload_id
        return unless requires_multipart_upload?

        strong_memoize(:upload_id) do
          new_upload = connection.initiate_multipart_upload(bucket_name, object_name)
          new_upload.body["UploadId"]
        end
      end

      def expire_at
        strong_memoize(:expire_at) do
          Time.now + TIMEOUT + EXPIRE_OFFSET
        end
      end

      def upload_options
        {}
      end

      def connection
        @connection ||= ::Fog::Storage.new(credentials)
      end
    end
  end

  module ObjectStorage
    class BackgroundMoveWorker
      include ApplicationWorker
      include ObjectStorageQueue

      sidekiq_options retry: 5

      def perform(uploader_class_name, subject_class_name, file_field, subject_id)
        uploader_class = uploader_class_name.constantize
        subject_class = subject_class_name.constantize

        return unless uploader_class < ObjectStorage::Concern
        return unless uploader_class.object_store_enabled?
        return unless uploader_class.background_upload_enabled?

        subject = subject_class.find(subject_id)
        uploader = build_uploader(subject, file_field&.to_sym)
        uploader.migrate!(ObjectStorage::Store::REMOTE)
      end

      def build_uploader(subject, mount_point)
        case subject
        when Upload then subject.build_uploader(mount_point)
        else
          subject.send(mount_point)
        end
      end
    end
  end

  module Gitlab
    # This class implements an 'exclusive lease'. We call it a 'lease'
    # because it has a set expiry time. We call it 'exclusive' because only
    # one caller may obtain a lease for a given key at a time. The
    # implementation is intended to work across GitLab processes and across
    # servers. It is a cheap alternative to using SQL queries and updates:
    # you do not need to change the SQL schema to start using
    # ExclusiveLease.
    #
    class ExclusiveLease
      LUA_CANCEL_SCRIPT = <<~EOS.freeze
      local key, uuid = KEYS[1], ARGV[1]
      if redis.call("get", key) == uuid then
        redis.call("del", key)
      end
      EOS

      LUA_RENEW_SCRIPT = <<~EOS.freeze
      local key, uuid, ttl = KEYS[1], ARGV[1], ARGV[2]
      if redis.call("get", key) == uuid then
        redis.call("expire", key, ttl)
        return uuid
      end
      EOS

      def self.get_uuid(key)
        Gitlab::Redis::SharedState.with do |redis|
          redis.get(redis_shared_state_key(key)) || false
        end
      end

      def self.cancel(key, uuid)
        Gitlab::Redis::SharedState.with do |redis|
          redis.eval(LUA_CANCEL_SCRIPT, keys: [redis_shared_state_key(key)], argv: [uuid])
        end
      end

      def self.redis_shared_state_key(key)
        "gitlab:exclusive_lease:#{key}"
      end

      # Removes any existing exclusive_lease from redis
      # Don't run this in a live system without making sure no one is using the leases
      def self.reset_all!(scope = '*')
        Gitlab::Redis::SharedState.with do |redis|
          redis.scan_each(match: redis_shared_state_key(scope)).each do |key|
            redis.del(key)
          end
        end
      end

      def initialize(key, uuid: nil, timeout:)
        @redis_shared_state_key = self.class.redis_shared_state_key(key)
        @timeout = timeout
        @uuid = uuid || SecureRandom.uuid
      end

      # Try to obtain the lease. Return lease UUID on success,
      # false if the lease is already taken.
      def try_obtain
        # Performing a single SET is atomic
        Gitlab::Redis::SharedState.with do |redis|
          redis.set(@redis_shared_state_key, @uuid, nx: true, ex: @timeout) && @uuid
        end
      end

      # Try to renew an existing lease. Return lease UUID on success,
      # false if the lease is taken by a different UUID or inexistent.
      def renew
        Gitlab::Redis::SharedState.with do |redis|
          result = redis.eval(LUA_RENEW_SCRIPT, keys: [@redis_shared_state_key], argv: [@uuid, @timeout])
          result == @uuid
        end
      end

      # Returns true if the key for this lease is set.
      def exists?
        Gitlab::Redis::SharedState.with do |redis|
          redis.exists(@redis_shared_state_key)
        end
      end

      # Returns the TTL of the Redis key.
      #
      # This method will return `nil` if no TTL could be obtained.
      def ttl
        Gitlab::Redis::SharedState.with do |redis|
          ttl = redis.ttl(@redis_shared_state_key)

          ttl if ttl.positive?
        end
      end
    end
  end

  module ApplicationWorker
    extend ActiveSupport::Concern

    include Sidekiq::Worker # rubocop:disable Cop/IncludeSidekiqWorker

    included do
      set_queue
    end

    class_methods do
      def inherited(subclass)
        subclass.set_queue
      end

      def set_queue
        queue_name = [queue_namespace, base_queue_name].compact.join(':')

        sidekiq_options queue: queue_name # rubocop:disable Cop/SidekiqOptionsQueue
      end

      def base_queue_name
        name
          .sub(/\AGitlab::/, '')
          .sub(/Worker\z/, '')
          .underscore
          .tr('/', '_')
      end

      def queue_namespace(new_namespace = nil)
        if new_namespace
          sidekiq_options queue_namespace: new_namespace

          set_queue
        else
          get_sidekiq_options['queue_namespace']&.to_s
        end
      end

      def queue
        get_sidekiq_options['queue'].to_s
      end

      def queue_size
        Sidekiq::Queue.new(queue).size
      end

      def bulk_perform_async(args_list)
        Sidekiq::Client.push_bulk('class' => self, 'args' => args_list)
      end

      def bulk_perform_in(delay, args_list)
        now = Time.now.to_i
        schedule = now + delay.to_i

        if schedule <= now
          raise ArgumentError, _('The schedule time must be in the future!')
        end

        Sidekiq::Client.push_bulk('class' => self, 'args' => args_list, 'at' => schedule)
      end
    end
  end

  module ObjectStorageQueue
    extend ActiveSupport::Concern

    included do
      queue_namespace :object_storage
    end
  end

  module Gitlab
    module Redis
      class SharedState < ::Gitlab::Redis::Wrapper
        SESSION_NAMESPACE = 'session:gitlab'.freeze
        USER_SESSIONS_NAMESPACE = 'session:user:gitlab'.freeze
        USER_SESSIONS_LOOKUP_NAMESPACE = 'session:lookup:user:gitlab'.freeze
        DEFAULT_REDIS_SHARED_STATE_URL = 'redis://localhost:6382'.freeze
        REDIS_SHARED_STATE_CONFIG_ENV_VAR_NAME = 'GITLAB_REDIS_SHARED_STATE_CONFIG_FILE'.freeze

        class << self
          def default_url
            DEFAULT_REDIS_SHARED_STATE_URL
          end

          def config_file_name
            # if ENV set for this class, use it even if it points to a file does not exist
            file_name = ENV[REDIS_SHARED_STATE_CONFIG_ENV_VAR_NAME]
            return file_name if file_name

            # otherwise, if config files exists for this class, use it
            file_name = config_file_path('redis.shared_state.yml')
            return file_name if File.file?(file_name)

            # this will force use of DEFAULT_REDIS_SHARED_STATE_URL when config file is absent
            super
          end
        end
      end
    end
  end

  module Gitlab
    module Redis
      class Wrapper
        DEFAULT_REDIS_URL = 'redis://localhost:6379'.freeze
        REDIS_CONFIG_ENV_VAR_NAME = 'GITLAB_REDIS_CONFIG_FILE'.freeze

        class << self
          delegate :params, :url, to: :new

          def with
            @pool ||= ConnectionPool.new(size: pool_size) { ::Redis.new(params) }
            @pool.with { |redis| yield redis }
          end

          def pool_size
            # heuristic constant 5 should be a config setting somewhere -- related to CPU count?
            size = 5
            if Sidekiq.server?
              # the pool will be used in a multi-threaded context
              size += Sidekiq.options[:concurrency]
            end

            size
          end

          def _raw_config
            return @_raw_config if defined?(@_raw_config)

            @_raw_config =
              begin
                if filename = config_file_name
                  ERB.new(File.read(filename)).result.freeze
                else
                  false
                end
              rescue Errno::ENOENT
                false
              end
          end

          def default_url
            DEFAULT_REDIS_URL
          end

          # Return the absolute path to a Rails configuration file
          #
          # We use this instead of `Rails.root` because for certain tasks
          # utilizing these classes, `Rails` might not be available.
          def config_file_path(filename)
            File.expand_path("../../../config/#{filename}", __dir__)
          end

          def config_file_name
            # if ENV set for wrapper class, use it even if it points to a file does not exist
            file_name = ENV[REDIS_CONFIG_ENV_VAR_NAME]
            return file_name unless file_name.nil?

            # otherwise, if config files exists for wrapper class, use it
            file_name = config_file_path('resque.yml')
            return file_name if File.file?(file_name)

            # nil will force use of DEFAULT_REDIS_URL when config file is absent
            nil
          end
        end

        def initialize(rails_env = nil)
          @rails_env = rails_env || ::Rails.env
        end

        def params
          redis_store_options
        end

        def url
          raw_config_hash[:url]
        end

        def sentinels
          raw_config_hash[:sentinels]
        end

        def sentinels?
          sentinels && !sentinels.empty?
        end

        private

        def redis_store_options
          config = raw_config_hash
          redis_url = config.delete(:url)
          redis_uri = URI.parse(redis_url)

          if redis_uri.scheme == 'unix'
            # Redis::Store does not handle Unix sockets well, so let's do it for them
            config[:path] = redis_uri.path
            query = redis_uri.query
            unless query.nil?
              queries = CGI.parse(redis_uri.query)
              db_numbers = queries["db"] if queries.key?("db")
              config[:db] = db_numbers[0].to_i if db_numbers.any?
            end

            config
          else
            redis_hash = ::Redis::Store::Factory.extract_host_options_from_uri(redis_url)
            # order is important here, sentinels must be after the connection keys.
            # {url: ..., port: ..., sentinels: [...]}
            redis_hash.merge(config)
          end
        end

        def raw_config_hash
          config_data = fetch_config

          if config_data
            config_data.is_a?(String) ? { url: config_data } : config_data.deep_symbolize_keys
          else
            { url: self.class.default_url }
          end
        end

        def fetch_config
          return false unless self.class._raw_config

          yaml = YAML.safe_load(self.class._raw_config)

          # If the file has content but it's invalid YAML, `load` returns false
          if yaml
            yaml.fetch(@rails_env, false)
          else
            false
          end
        end
      end
    end
  end
end
