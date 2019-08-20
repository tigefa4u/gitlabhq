# frozen_string_literal: true

module MetadataLogger
  SIDEKIQ_JOB_METADATA_KEY = :sidekiq_job_metadata

  def store_job_metadata(project:, user:, details: {})
    return unless ::Gitlab::SafeRequestStore.active?

    save_metadata(
      details.merge(
        {
          project_id: project&.id,
          project_path: project&.full_path,
          username: user&.username,
          user_id: user&.id
        })
    )
  end

  def self.job_metadata
    ::Gitlab::SafeRequestStore[SIDEKIQ_JOB_METADATA_KEY]
  end

  private

  def save_metadata(metadata)
    ::Gitlab::SafeRequestStore[SIDEKIQ_JOB_METADATA_KEY] ||= {}
    ::Gitlab::SafeRequestStore[SIDEKIQ_JOB_METADATA_KEY].merge(metadata.compact)
  end
end
