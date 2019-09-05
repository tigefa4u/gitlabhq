# frozen_string_literal: true

module Projects
  module HashedStorage
    # Returned when repository can't be made read-only because there is already a git transfer in progress
    RepositoryInUseError = Class.new(StandardError)

    class BaseRepositoryService < BaseService
      include Gitlab::ShellAdapter

      attr_reader :old_disk_path, :new_disk_path, :old_wiki_disk_path, :old_storage_version, :logger, :move_wiki

      def initialize(project, old_disk_path, logger: nil)
        @project = project
        @logger = logger || Gitlab::AppLogger
        @old_disk_path = old_disk_path
        @old_wiki_disk_path = "#{old_disk_path}.wiki"
        @move_wiki = has_wiki?
      end

      protected

      # rubocop: disable CodeReuse/ActiveRecord
      def has_wiki?
        gitlab_shell.exists?(project.repository_storage, "#{old_wiki_disk_path}.git")
      end
      # rubocop: enable CodeReuse/ActiveRecord

      # rubocop: disable CodeReuse/ActiveRecord
      def move_repository(from_name, to_name)
        from_exists = gitlab_shell.exists?(project.repository_storage, "#{from_name}.git")

        # If we don't find the repository on either original or target we should log that as it could be an issue if the
        # project was not originally empty.

        # Repository have been moved already.
        return true unless from_exists

        gitlab_shell.mv_repository(project.repository_storage, from_name, to_name)
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def rollback_folder_move
        move_repository(new_disk_path, old_disk_path)
        move_repository("#{new_disk_path}.wiki", old_wiki_disk_path)
      end

      def try_to_set_repository_read_only!
        # Mitigate any push operation to start during migration
        unless project.set_repository_read_only!
          migration_error = "Target repository '#{old_disk_path}' cannot be made read-only as there is a git transfer in progress"
          logger.error migration_error

          raise RepositoryInUseError, migration_error
        end
      end
    end
  end
end
