# frozen_string_literal: true

class Int4PkStage1Step5of5 < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    if Gitlab::Database.postgresql?
      # Redefine PK of the "events" table
      execute("drop index index_push_event_payloads_on_event_id;")
      execute <<-SQL.strip_heredoc
        alter table events add constraint events_pkey
          primary key using index events_id_new_idx;
      SQL
      execute("alter table events drop constraint id_new_not_null;")

      # Define PK on "push_event_payloads".
      # (Before, no PK was present at all – only a unique index.)
      execute "drop index index_push_event_payloads_on_event_id;" # "concurrently"?
      execute <<-SQL.strip_heredoc
        alter table push_event_payloads add constraint push_event_payloads_pkey
          primary key using index push_event_payloads_event_id_new_idx;
      SQL
      execute("alter table push_event_payloads drop constraint event_id_new_not_null;")

      # Swap columns
      execute <<-SQL.strip_heredoc
        alter table events rename id to id_old;
        alter table events rename id_new to id;
        alter table events alter column id set default nextval('events_id_seq');
        alter sequence events_id_seq owned by events.id;

        alter table push_event_payloads rename event_id to event_id_old;
        alter table events rename event_id_new to event_id;
      SQL

      # Final cleanup 
      remove_rename_triggers_for_postgresql(:events, 'int4_to_int8')
      remove_column(:events, :id_old)
      int4_to_int8_forget_max_value(:events, :id)

      remove_rename_triggers_for_postgresql(:push_event_payloads, 'int4_to_int8')
      remove_column(:push_event_payloads, :event_id_old)
      int4_to_int8_forget_max_value(:push_event_payloads, :event_id)

      #execute "alter table public.events set (autovacuum_enabled = true);"
      #execute "alter table public.push_event_payloads set (autovacuum_enabled = true);"
    end

    if Gitlab::Database.mysql?
      change_column(:events, :id, :bigint) # slow!
      change_column(:push_event_payloads, :event_id, :bigint) # slow!
    end
  end

  def down
    if Gitlab::Database.postgresql?
      # Warning: this "UNDO" migration step causes multiple long expensive locks.

      execute "alter table push_event_payloads drop constraint fk_36c74129da;"
      change_column(:events, :id, :integer, :limit => 4) # Very slow on large tables
      change_column(:push_event_payloads, :event_id, :integer, :limit => 4) # Very slow on large tables

      add_column(:events, :id_new, :bigint)
      install_rename_triggers_for_postgresql(:int4_to_int8, :events, :id, :id_new, 'INSERT')
      int4_to_int8_remember_max_value(:events, :id, :id_new)

      add_column(:event_payloads, :event_id_new, :bigint)
      install_rename_triggers_for_postgresql(:int4_to_int8, :push_event_payloads, :event_id, :event_id_new, 'INSERT')
      int4_to_int8_remember_max_value(:push_event_payloads, :event_id, :event_id_new)

      execute("alter table events add constraint id_new_not_null check (id_new is not null);") # Very slow on large tables
      execute("alter table push_event_payloads add constraint event_id_new_not_null check (event_id_new is not null);") # Very slow on large tables

      #execute "alter table public.events set (autovacuum_enabled = false);"
      #execute "alter table public.push_event_payloads set (autovacuum_enabled = false);"

      add_index(:events, :id_new, unique: true, name: :events_id_new_idx) # Very slow on large tables
      add_index(:push_event_payloads, :event_id_new, unique: true, name: :push_event_payloads_event_id_new_idx) # Very slow on large tables

      execute <<-SQL.strip_heredoc
        alter table push_event_payloads add constraint fk_36c74129da
          foreign key (event_id_new) references events(id_new) on delete cascade;
      SQL
    end

    if Gitlab::Database.mysql?
      change_column(:push_event_payloads, :event_id, :int) # slow!
      change_column(:events, :id, :int) # slow!
    end
  end
end
