# frozen_string_literal: true

module Ci
  class DeleteStoredArtifactsWorker
    include ApplicationWorker

    def perform(artifact_files)
      artifact_files.each(&:remove!)
    end
  end
end
