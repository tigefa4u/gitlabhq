# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Finds the next batch and processes it, filling "new_column" copying
    # values from "old_column". Only PostgreSQL is supported.
    # Parallel execution is allowed (protected by "FOR UPDATE SKIP LOCKED",
    # see https://www.postgresql.org/docs/9.6/sql-select.html#SQL-FOR-UPDATE-SHARE)
    #
    # If non-zero amount of rows has been processed, the rescheduling is
    # performed (the new job is scheduled, with same parameters, except one:
    # "last_processed").
    #
    # Since parallel execution is allowed, it is possible to schedule
    # N jobs in sidekiq, to utilize N workers and speed up processing.
    #
    # table: table name
    # old_column: old column name (for example, "id")
    # new_column: new column name (for example, "id_new")
    # delay: delay in seconds for rescheduling
    # batch_size: the size of 1 batch (how many rows are updated by 1 statement)
    # batches_per_iteration: how many batches to process in one iteration
    # last_processed: the last processed value of the "old column". This is
    #                  being passed explicitly to simplify debugging and
    #                  monitoring: both SQL and sidekiq logs will have it,
    #                  which simplifies tracking the progress.
    class Int4ToInt8Update
      def log(message)
        Rails.logger.info("#{self.class.name} - #{message}")
      end

      def perform(table, old_column, new_column, delay, batch_size, batches_per_iteration, last_processed = 0)
        if Database.mysql?
          raise 'Int4ToInt8Update is not supported for MySQL'
        end

        rescheduling_needed = true

        batches_per_iteration.times do
          # Lock #{batch_size} rows, skipping those already locked,
          # then UPDATE them, and return number of updated rows,
          # as well as min and max values.
          result = ActiveRecord::Base.connection.execute <<~SQL.strip_heredoc
            WITH rows_to_update AS (
              SELECT #{old_column}
              FROM #{table}
              WHERE
                #{old_column} > #{last_processed}
                AND #{new_column} IS NULL
              ORDER BY #{old_column}
              LIMIT #{batch_size}
              FOR UPDATE SKIP LOCKED
            ), upd AS (
              UPDATE #{table}
              SET #{new_column} = #{old_column}
              WHERE #{old_column} IN (SELECT #{old_column} FROM rows_to_update)
              RETURNING #{old_column}
            )
            SELECT
              COUNT(*) AS cnt,
              MIN(#{old_column}) AS min_val,
              MAX(#{old_column}) AS max_val
            FROM upd;
          SQL

          # If nothing has been processed, we assume that nothing is left.
          # So it's time to stop the processing, rescheduling is not needed.
          if result[0]['cnt'] == 0
            rescheduling_needed = false
            break
          end

          last_processed = result[0]['max_val']

          log("#{table}.#{old_column} = #{result[0]['min_val']}..#{result[0]['max_val']}")
        end

        if rescheduling_needed
          BackgroundMigrationWorker.perform_in(
            delay,
            self.class.name.demodulize,
            [table, old_column, new_column, delay, batch_size, batches_per_iteration, last_processed]
          )
        end
      end
    end
  end
end
