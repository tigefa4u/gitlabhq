# frozen_string_literal: true

class Int4PkStage1of2Index < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    # Create 3 helper indexes to speed up background migrations.
    # These indexes are to be removed in the next release.

    # Time estimate for GitLab.com: ~420s (~7 min)
    add_index_for_new_field(:events, :id)

    # Time estimate for GitLab.com: ~360s (~6 min)
    add_index_for_new_field(:push_event_payloads, :event_id)

    # Time estimate for GitLab.com: ~840s (~14 min)
    add_index_for_new_field(:ci_build_trace_sections, :id)
  end

  def down
    remove_concurrent_index_by_name(:ci_build_trace_sections, :ci_build_trace_sections_int4_to_int8_helper)
    remove_concurrent_index_by_name(:push_event_payloads, :push_event_payloads_int4_to_int8_helper)
    remove_concurrent_index_by_name(:events, :events_int4_to_int8_helper)
  end

  def add_index_for_new_field(table, field)
    name = "#{table}_int4_to_int8_helper"

    remove_concurrent_index_by_name(table, name)

    add_concurrent_index(
      table,
      field,
      name: name,
      where: "#{field}_new is null"
    )
  end
end
