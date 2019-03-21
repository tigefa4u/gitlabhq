# frozen_string_literal: true

module Projects
  class AfterImportService
    RESERVED_REF_PREFIXES = Repository::RESERVED_REFS_NAMES.map { |n| File.join('refs', n, '/') }

    def initialize(project)
      @project = project
    end

    def execute
      Projects::HousekeepingService.new(@project).execute do
        repository.delete_all_refs_except(RESERVED_REF_PREFIXES)
      end
    rescue Projects::HousekeepingService::LeaseTaken => e
      Rails.logger.info(
        _("Could not perform housekeeping for project %{project_full_path} (%{project_id}): %{e}") % { project_full_path: @project.full_path, project_id: @project.id, e: e })
    end

    private

    def repository
      @repository ||= @project.repository
    end
  end
end
