# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class Int4ToInt8Update
      def log(message)
        Rails.logger.info("#{self.class.name} - #{message}")
      end

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
      # table – table name
      # old_column - old column name (for example, "id")
      # new_column – new column name (for example, "id_new")
      # delay – delay in seconds for rescheduling
      # batch_size – the size of 1 batch (how many rows are updated by 1 statement)
      # batches_per_iteration – how many batches to process in one iteration
      # last_processed – the last processed value of the "old column". This is
      #                  being passed explicitly to simplify debugging and
      #                  monitoring: both SQL and sidekiq logs will have it,
      #                  which simplifies tracking the progress.
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
            with rows_to_update as (
              select #{old_column}
              from #{table}
              where
                #{old_column} > #{last_processed}
                and #{new_column} is null
              order by #{old_column}
              limit #{batch_size}
              for update skip locked
            ), upd as (
              update #{table}
              set #{new_column} = #{old_column}
              where #{old_column} in (select #{old_column} from rows_to_update)
              returning #{old_column}
            )
            select
              count(*) as cnt,
              min(#{old_column}) as min_val,
              max(#{old_column}) as max_val
            from upd;
          SQL

          # If nothing has been processed, we assume that nothing is left.
          # So it's time to stop the processing, rescheduling is not needed.
          if result[0]['cnt'] == 0 then
            rescheduling_needed = false
            break
          end

          last_processed = result[0]['max_val']

          log("#{table}.#{old_column} = #{result[0]['min_val']}..#{result[0]['max_val']}")
        end

        if rescheduling_needed then
          BackgroundMigrationWorker.perform_in(
            delay,
            "Int4ToInt8Update",
            [table, old_column, new_column, delay, batch_size, batches_per_iteration, last_processed]
          )
        end
      end
    end
  end
end
