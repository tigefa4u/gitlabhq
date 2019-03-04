# frozen_string_literal: true

class Int4PkStage1of2NewColumn < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    add_column(:events, :id_new, :bigint)
#    add_column(:push_event_payloads, :event_id_new, :bigint)
#    add_column(:ci_build_trace_sections, :id_new, :bigint)
  end

  def down
#    remove_column(:ci_build_trace_sections, :id_new)
#    remove_column(:push_event_payloads, :event_id_new)
    remove_column(:events, :id_new)
  end
end
