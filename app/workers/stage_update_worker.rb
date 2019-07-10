# frozen_string_literal: true

class StageUpdateWorker
  include ApplicationWorker
  include PipelineQueue

  queue_namespace :pipeline_processing

  def self.sidekiq_status_enabled?
    false
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def perform(stage_id)
    Ci::Stage.find_by(id: stage_id).try do |stage|
      stage.update_status
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
