# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class Int4ToInt8Update
      def log(message)
        Rails.logger.info("#{self.class.name} - #{message}")
      end

      def perform(table, old_column, new_column, delay, batch_size, batches_per_iteration)
        if Database.mysql?
          raise 'Int4ToInt8Update is not supported for MySQL'
        end

        rescheduling_needed = true

        batches_per_iteration.times do
          result = ActiveRecord::Base.connection.execute <<~SQL.strip_heredoc
            with rows_to_update as (
              select #{old_column}
              from #{table}
              where #{new_column} is null
              order by #{old_column}
              limit #{batch_size}
              for update skip locked
            ), upd as (
              update #{table}
              set #{new_column} = #{old_column}
              where #{old_column} in (select #{old_column} from rows_to_update)
              returning id
            )
            select
              count(*) as cnt,
              min(id) as min_id,
              max(id) as max_id
            from upd;
          SQL

          if result[0]['cnt'] == 0 then
            # Nothing left. So it's time to stop the processing.
            rescheduling_needed = false
            break
          end

          log("#{table}.#{old_column} = #{result[0]['min_id']}..#{result[0]['max_id']}")
        end

        if rescheduling_needed then
          BackgroundMigrationWorker.perform_in(
            delay,
            "Int4ToInt8Update",
            [table, old_column, new_column, delay, batch_size, batches_per_iteration]
          )
        end
      end
    end

    #class Int4toInt8UpdatePushEventPayloads
    #  def perform(start_id, stop_id)
    #    ActiveRecord::Base.connection.execute <<~SQL
    #      update push_event_payloads
    #      set event_id_new = event_id
    #      where id between #{start_id} and #{end_id}
    #    SQL
    #  end
    #end

    #class Int4toInt8UpdateCiBuildTraceSections
    #  def perform(start_id, stop_id)
    #    ActiveRecord::Base.connection.execute <<~SQL
    #      update ci_build_trace_sections
    #      set id_new = id
    #      where id between #{start_id} and #{end_id}
    #    SQL
    #  end
    #end

  end
end

