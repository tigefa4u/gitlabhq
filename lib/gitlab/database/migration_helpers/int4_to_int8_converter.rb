module Gitlab
  module Database
    module MigrationHelpers
      module Int4ToInt8Converter

        # Copies values from `old_column` to `new_column`, processing only `chunk_size` rows
        # and reporting progress. PostgreSQL only.
        #
        # This is a helper method for converting int4 PKs (and corresponding FK columns)
        # to int8 in Postgres. An index on `new_column` must exist.
        def int4_to_int8_copy(table, old_column, new_column, chunk_size = 2000)
          if Database.mysql?
            raise 'int4_to_int8_copy is not supported for MySQL'
          end

          # int4_to_int8_copy requires "disable_ddl_transaction!"
          if transaction_open?
            raise 'add_concurrent_check_constraint can not be run inside an open transaction'
          end

          bar = ProgressBar.create(:total => 101)

          i = 0
          loop do
            upper_border = connection.select_value("select current_setting('int4_to_int8.#{table}.#{old_column}')")
            res = execute <<-SQL.strip_heredoc
              with upd as (
                update #{table}
                set #{new_column} = #{old_column}
                where #{old_column} in (
                  select #{old_column}
                  from #{table}
                  where
                    #{old_column} > coalesce(
                      (select max(#{new_column}) from #{table} where #{new_column} < #{upper_border}),
                      0
                    )
                    and #{old_column} < #{upper_border}
                  order by #{old_column} limit #{chunk_size}
                )
                returning #{new_column}
              )
              select
                (select count(*) from upd) as rows_updated,
                (select max(#{new_column}) from upd) as last_updated_value,
                (select max(#{old_column}) from #{table}) as max_existing_value,
                (
                  select round((select max(#{new_column}) from upd)::numeric * 100
                  / (select max(#{old_column}) from #{table}), 2)
                ) as progress_percent
              ;
            SQL

            i = i + 1
            if i % 1000 == 0
              say("int4→int8 table: #{table}, i: #{i}, last: #{res[0]['last_updated_value'].to_s}, progress (est.): #{res[0]['progress_percent'].to_s}%")

              #say("Run 'manual' VACUUM for table #{table}")
              #execute "vacuum #{table}"
            end

            break if not (res[0]['rows_updated'].to_i > 0)

            bar.total = res[0]['max_existing_value'].to_i
            bar.format("Processing #{table}: %w> (rate: %R)")
            bar.progress = res[0]['last_updated_value'].to_i
          end

          say("int4→int8 table: #{table}. DONE.")

          #say("Run 'manual' VACUUM ANALYZE for table #{table}")
          #execute "vacuum analyze #{table}"
        end
      end
    end
  end
end
