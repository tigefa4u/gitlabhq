# frozen_string_literal: true

class Int4PkStage1of2Index < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    # Create 3 helper indexes to speed up background migrations.
    # These indexes are to be removed in the next release.

    remove_concurrent_index_by_name(:events, :events_int4_to_int8_helper)
    # Time estimate for GitLab.com: ~420s (~7 min)
    add_concurrent_index(
      :events,
      :id,
      name: :events_int4_to_int8_helper,
      where: 'id_new is null'
    )

    remove_concurrent_index_by_name(:events, :push_event_payloads_int4_to_int8_helper)
    # Time estimate for GitLab.com: ~360s (~6 min)
    add_concurrent_index(
      :push_event_payloads,
      :event_id,
      name: :push_event_payloads_int4_to_int8_helper,
      where: 'event_id_new is null'
    )

    remove_concurrent_index_by_name(:ci_build_trace_sections, :ci_build_trace_sections_int4_to_int8_helper)
    # Time estimate for GitLab.com: ~840s (~14 min)
    add_concurrent_index(
      :ci_build_trace_sections,
      :id,
      name: :ci_build_trace_sections_int4_to_int8_helper,
      where: 'id_new is null'
    )
  end

  def down
    remove_concurrent_index_by_name(:ci_build_trace_sections, :ci_build_trace_sections_int4_to_int8_helper)
    remove_concurrent_index_by_name(:events, :push_event_payloads_int4_to_int8_helper)
    remove_concurrent_index_by_name(:events, :events_int4_to_int8_helper)
  end
end
