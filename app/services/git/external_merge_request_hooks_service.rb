# frozen_string_literal: true

module Git
  class ExternalMergeRequestHooksService < ::Git::BaseHooksService
    include Gitlab::Utils::StrongMemoize

    private

    def pipeline_source
      :external_merge_request
    end

    def hook_name
      :external_merge_request_hooks
    end

    def commits
      # TODO: test this works
      project.repository.commits(params[:ref], limit: 10)
    end

    # TODO: remove this to use the implementation from the parent class.
    # we need to first ensure that projet.has_remote_mirror? is not true for
    # mirror projects
    def update_remote_mirrors
      return unless project.has_remote_mirror?

      project.mark_stuck_remote_mirrors_as_failed!
      project.update_remote_mirrors
    end
  end
end
