# frozen_string_literal: true

module Ci
  class ArchiveTracesCronWorker
    include ApplicationWorker
    include CronjobQueue

    # rubocop: disable CodeReuse/ActiveRecord
    def perform
      # Archive stale live traces which still resides in redis or database
      # This could happen when ArchiveTraceWorker sidekiq jobs were lost by receiving SIGKILL
      # More details in https://gitlab.com/gitlab-org/gitlab-ce/issues/36791
      Ci::Build.finished.with_live_trace.find_each(batch_size: 100) do |build|
        if Feature.enabled?(:ci_archive_trace_async)
          ArchiveTraceWorker.perform_async(build.id)
        else
          begin
            Ci::ArchiveTraceService.new.execute(build)
          ensure
            ##
            # This is the temporary solution for avoiding the memory bloat.
            # See more https://gitlab.com/gitlab-com/gl-infra/infrastructure/issues/4667#note_192401907
            GC.start if Feature.enabled?(:ci_archive_trace_force_gc, default_enabled: true)
          end
        end
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
