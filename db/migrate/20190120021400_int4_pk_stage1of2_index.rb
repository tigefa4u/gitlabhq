# frozen_string_literal: true

class Int4PkStage1of2Index < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    # Time estimate for GitLab.com: ~420s (~7 min)
    remove_concurrent_index_by_name(:events, :events_int4_to_int8_helper)
    add_concurrent_index(
      :events,
      :id_new,
      name: :events_int4_to_int8_helper,
      where: 'id_new is null'
    )
  end

  def down
    remove_concurrent_index_by_name(:events, :events_int4_to_int8_helper)
  end
end

