# frozen_string_literal: true

class Int4PkStage1of2NewColumn < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    add_column(:events, :id_new, :bigint)
    add_column(:push_event_payloads, :event_id_new, :bigint)
    add_column(:ci_build_trace_sections, :id_new, :bigint)

    if Gitlab::Database.postgresql?
      install_rename_triggers_for_postgresql(:int4_to_int8, :events, :id, :id_new, 'INSERT')
      install_rename_triggers_for_postgresql(:int4_to_int8, :push_event_payloads, :event_id, :event_id_new, 'INSERT')
      install_rename_triggers_for_postgresql(:int4_to_int8, :ci_build_trace_sections, :id, :id_new, 'INSERT')
    end
  end

  def down
    if Gitlab::Database.postgresql?
      remove_rename_triggers_for_postgresql(:ci_build_trace_sections, :'int4_to_int8')
      remove_rename_triggers_for_postgresql(:push_event_payloads, :'int4_to_int8')
      remove_rename_triggers_for_postgresql(:events, :'int4_to_int8')
    end

    remove_column(:ci_build_trace_sections, :id_new)
    remove_column(:push_event_payloads, :event_id_new)
    remove_column(:events, :id_new)
  end
end
