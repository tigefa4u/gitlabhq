# frozen_string_literal: true

# State column will be removed in a post deployment migration
# This build all indexes that uses issues and merge_requests state column
# using the new state_id column.
class AddStateIdIndexes < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index(
      :issues,
      [:project_id, :created_at, :id, :state_id],
      name: "idx_issues_on_project_id_created_at_id_and_state_id"
    )

    add_concurrent_index(
      :issues,
      [:project_id, :due_date, :id, :state_id],
      name: "idx_issues_on_project_id_due_date_id_and_state_id",
      where: "(due_date IS NOT NULL)"
    )

    add_concurrent_index(
      :issues,
      [:project_id, :updated_at, :id, :state_id],
      name: "idx_issues_on_project_id_and_updated_at_and_id_and_state_id"
    )

    add_concurrent_index(
      :issues,
      :state_id,
      name: "idx_issues_on_state_id"
    )

    add_concurrent_index(
      :merge_requests,
      [:id, :merge_jid],
      where: "merge_jid IS NOT NULL and state_id = 4",
      name: "idx_merge_requests_on_id_merge_jid_state_id_locked"
    )

    add_concurrent_index(
      :merge_requests,
      [:source_project_id, :source_branch],
      where: "state_id = 1",
      name: "idx_merge_requests_on_source_project_and_branch_state_id_opened"
    )

    add_concurrent_index(
      :merge_requests,
      [:target_project_id, :iid],
      where: "state_id = 1",
      name: "idx_merge_requests_on_target_project_id_and_iid_state_id_opened"
    )
  end

  def down
    remove_concurrent_index_by_name(:issues, "idx_issues_on_project_id_created_at_id_and_state_id")
    remove_concurrent_index_by_name(:issues, "idx_issues_on_state_id")
    remove_concurrent_index_by_name(:issues, "idx_issues_on_project_id_due_date_id_and_state_id")
    remove_concurrent_index_by_name(:issues, "idx_issues_on_project_id_and_updated_at_and_id_and_state_id")
    remove_concurrent_index_by_name(:merge_requests, "idx_merge_requests_on_id_merge_jid_state_id_locked")
    remove_concurrent_index_by_name(:merge_requests, "idx_merge_requests_on_source_project_and_branch_state_id_opened")
    remove_concurrent_index_by_name(:merge_requests, "idx_merge_requests_on_target_project_id_and_iid_state_id_opened")
  end
end
