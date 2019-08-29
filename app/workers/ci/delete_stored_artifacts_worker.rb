# frozen_string_literal: true

module Ci
  class DeleteStoredArtifactsWorker
    include ApplicationWorker

    def perform(project_id, store_path, local_store, size)
      Project.find_by_id(project_id).try do |project|
        Ci::DeleteStoredArtifactsService.new(project).execute(store_path, local_store)

        UpdateProjectStatistics.update_project_statistics!(project, :build_artifacts_size, -size)
      end
    end
  end
end
