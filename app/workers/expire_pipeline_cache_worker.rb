# frozen_string_literal: true

class ExpirePipelineCacheWorker
  include ApplicationWorker
  include PipelineQueue

  queue_namespace :pipeline_cache

  def self.sidekiq_status_enabled?
    false
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def perform(pipeline_id)
    pipeline = Ci::Pipeline.find_by(id: pipeline_id)
    return unless pipeline

    Ci::ExpirePipelineCacheService.new.execute(pipeline)
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
