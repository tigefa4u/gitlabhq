class Int4PkStage1of2FillColumn < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction! 

  DOWNTIME = false

  DELAY = 2.minutes.to_i
  BATCH_SIZE = 2_500
  BATCHES_IN_ITERATION = 10
  CONCURRENCY = 5
  MIGRATION = 'Int4ToInt8Update'

  def up
    say('Scheduling `Int4toInt8Update` jobs')

    CONCURRENCY.times do
      BackgroundMigrationWorker.perform_in(
        DELAY,
        MIGRATION,
        [:events, :id, :id_new, DELAY, BATCH_SIZE, BATCHES_IN_ITERATION]
      )
    end

    #queue_background_migration_jobs_by_range_at_intervals(
    #  PushEventPayload,
    #  PUSH_EVENT_PAYLOADS_MIGRATION,
    #  DELAY,
    #  batch_size: BATCH_SIZE
    #)

    #queue_background_migration_jobs_by_range_at_intervals(
    #  CiBuildTraceSection,
    #  CI_BUILD_TRACE_SECTIONS_MIGRATION,
    #  DELAY,
    #  batch_size: BATCH_SIZE
    #)
  end

  def down
    # No op
  end
end
