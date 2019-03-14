class Int4PkStage1of2FillColumn < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  DOWNTIME = false

  DELAY = 2.minutes.to_i
  BATCH_SIZE = 2_500
  BATCHES_PER_ITERATION = 20
  CONCURRENCY = 5
  MIGRATION = 'Int4ToInt8Update'

  def up
    return unless Gitlab::Database.postgresql?

    say('Scheduling `Int4toInt8Update` jobs')

    # [GitLab.com] events: ~290M rows, heap 19 GiB
    CONCURRENCY.times do
      BackgroundMigrationWorker.perform_in(
        DELAY,
        MIGRATION,
        [:events, :id, :id_new, DELAY, BATCH_SIZE, BATCHES_PER_ITERATION]
      )
    end

    # [GitLab.com] push_event_payloads: ~220M rows, heap 27 GiB
    CONCURRENCY.times do
      BackgroundMigrationWorker.perform_in(
        DELAY + 20,
        MIGRATION,
        [:push_event_payloads, :event_id, :event_id_new, DELAY, BATCH_SIZE, BATCHES_PER_ITERATION]
      )
    end

    # [GitLab.com] ci_build_trace_sections: ~600M rows, heap 43 GiB
    CONCURRENCY.times do
      BackgroundMigrationWorker.perform_in(
        DELAY + 40,
        MIGRATION,
        [:ci_build_trace_sections, :id, :id_new, DELAY, BATCH_SIZE, BATCHES_PER_ITERATION]
      )
    end
  end

  def down
    # No op
  end
end
