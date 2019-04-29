class RemoveStateFromIssuesAndMergeRequests < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def issuable_states
    { "opened" => 1, "closed" => 2, "merged" => 3, "locked" => 4 }
  end

  def up
    remove_column :issues, :state
    remove_column :merge_requests, :state
  end

  def down
    add_column :issues, :state, :string
    add_column :merge_requests, :state, :string

    issuable_states.each do |state_name, state_id|
      # "merged" and "locked" states does not apply for issues
      if state_id < 3
        update_column_in_batches(:issues, :state, state_name) do |table, query|
          query.where(table[:state_id].eq(state_id))
        end
      end

      update_column_in_batches(:merge_requests, :state, state_name) do |table, query|
        query.where(table[:state_id].eq(state_id))
      end
    end

    # Only required for merge requests
    change_column_null :merge_requests, :state, true
    change_column_default :merge_requests, :state, "opened"

    rebuild_indexes
  end

  def rebuild_indexes
    add_concurrent_index(
      :issues,
      [:project_id, :created_at, :id, :state],
      name: "index_issues_on_project_id_and_created_at_and_id_and_state"
    )

    add_concurrent_index(
      :issues,
      [:project_id, :due_date, :id, :state],
      name: "idx_issues_on_project_id_and_due_date_and_id_and_state_partial",
      where: "(due_date IS NOT NULL)"
    )

    add_concurrent_index(
      :issues,
      [:project_id, :updated_at, :id, :state],
      name: "index_issues_on_project_id_and_updated_at_and_id_and_state"
    )

    add_concurrent_index(
      :issues,
      :state,
      name: "index_issues_on_state"
    )

    add_concurrent_index(
      :merge_requests,
      [:id, :merge_jid],
      where: "merge_jid IS NOT NULL and state = 'locked'",
      name: "index_merge_requests_on_id_and_merge_jid"
    )

    add_concurrent_index(
      :merge_requests,
      [:source_project_id, :source_branch],
      where: "state = 'opened'",
      name: "index_merge_requests_on_source_project_and_branch_state_opened"
    )

    add_concurrent_index(
      :merge_requests,
      [:target_project_id, :iid],
      where: "state = 'opened'",
      name: "index_merge_requests_on_target_project_id_and_iid_opened"
    )
  end
end
