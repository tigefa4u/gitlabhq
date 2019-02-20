# frozen_string_literal: true

class Int4PkStage1Step2of5 < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    # Cleanup: drop invalid index(es) if there was a failed attempt to execute this migration before.
    remove_concurrent_index_by_name(:events, :events_id_new_idx)
    remove_concurrent_index_by_name(:push_event_payloads, :push_event_payloads_event_id_new_idx)
    remove_concurrent_index_by_name(:ci_build_trace_sections, :ci_build_trace_sections_id_new_idx)

    # Time estimate for GitLab.com: ~420s (~7 min)
    add_concurrent_index(:events, :id_new, unique: true, name: :events_id_new_idx)

    # Time estimate for GitLab.com: ~360s (~6 min)
    add_concurrent_index(:push_event_payloads, :event_id_new, unique: true, name: :push_event_payloads_event_id_new_idx)

    # Time estimate for GitLab.com: TBD
    add_concurrent_index(:ci_build_trace_sections, :id_new, unique: true, name: :ci_build_trace_sections_id_new_idx)

    if Gitlab::Database.postgresql?
      # Remember upper bounds of IDs of existing rows, put it to database GUC variables
      int4_to_int8_remember_max_value(:events, :id, :id_new)
      int4_to_int8_remember_max_value(:push_event_payloads, :event_id, :event_id_new)
      int4_to_int8_remember_max_value(:ci_build_trace_sections, :id, :id_new)
    end
  end

  def down
    if Gitlab::Database.postgresql?
      int4_to_int8_forget_max_value(:ci_build_trace_sections, :id)
      int4_to_int8_forget_max_value(:push_event_payloads, :event_id)
      int4_to_int8_forget_max_value(:events, :id)
    end

    remove_concurrent_index_by_name(:ci_build_trace_sections, :ci_build_trace_sections_id_new_idx)
    remove_concurrent_index_by_name(:push_event_payloads, :push_event_payloads_event_id_new_idx)
    remove_concurrent_index_by_name(:events, :events_id_new_idx)
  end
end
