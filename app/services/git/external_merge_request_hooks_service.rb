# frozen_string_literal: true

module Git
  class ExternalMergeRequestHooksService  < ::Git::BaseHooksService
    include Gitlab::Utils::StrongMemoize

    def create_pipelines
      return unless params.fetch(:create_pipelines, true)

      Ci::CreatePipelineService
        .new(project, current_user, push_data)
        .execute(:external_merge_request, pipeline_options)
    end

    private

    def hook_name
      :external_merge_request_hooks
    end

    def commits
      raise NotImplementedError, "Please implement #{self.class}##{__method__}"
    end

    def update_remote_mirrors
      return unless project.has_remote_mirror?

      project.mark_stuck_remote_mirrors_as_failed!
      project.update_remote_mirrors
    end
  end
end
