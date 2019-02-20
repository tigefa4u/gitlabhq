# frozen_string_literal: true

class Int4PkStage1Step4of5 < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    return unless Gitlab::Database.postgresql?

    # Creation of PK requires NOT NULL constraint to be already enforced.
    # Regular NOT NULL constraint creation means a long lock on the table.
    # Instead of it, we use an equivalent CHECK constraint here.
    add_concurrent_check_constraint(:events, :id_new_not_null, 'id_new is not null')
    add_concurrent_check_constraint(:push_event_payloads, :event_id_new_not_null, 'event_id_new is not null')

    # Recreate FK
    execute "alter table push_event_payloads drop constraint if exists fk_36c74129da_new;"
    execute <<-SQL.strip_heredoc
      alter table push_event_payloads add constraint fk_36c74129da_new
        foreign key (event_id_new) references events(id_new) not valid on delete cascade;
    SQL
    execute("alter table push_event_payloads validate constraint fk_36c74129da_new;") # long
    execute("alter table push_event_payloads drop constraint fk_36c74129da;")
    execute("alter table push_event_payloads rename constraint fk_36c74129da_new to fk_36c74129da;")
  end

  def down
    return unless Gitlab::Database.postgresql?

    # Restore the old version of the FK. At this point, the FK is defined on "**_new" columns.
    execute "alter table push_event_payloads drop constraint if exists fk_36c74129da_old;"
    execute <<-SQL.strip_heredoc
      alter table push_event_payloads add constraint fk_36c74129da_old
        foreign key (event_id) references events(id) not valid on delete cascade;
    SQL
    execute("alter table push_event_payloads validate constraint fk_36c74129da_old;") # long
    execute("alter table push_event_payloads drop constraint fk_36c74129da;")
    execute("alter table push_event_payloads rename constraint fk_36c74129da_old to fk_36c74129da;")

    # Remove CHECK constraints (they must exist at this point)
    execute("alter table push_event_payloads drop constraint event_id_new_not_null;")
    execute("alter table events drop constraint id_new_not_null;")
  end
end
