# frozen_string_literal: true


class Int4PkStage1Step3of5 < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers
  include Gitlab::Database::MigrationHelpers::Int4ToInt8Converter

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    return unless Gitlab::Database.postgresql?

    # Process existing rows in batches.
    # If it fails, it is OK to re-run this migration. The processing will
    # automatically continue from the position where it failed.

    # Once this migration successfully finished, there are no NULL values
    # in there "new" columns.

    # GitLab.com: ~300M rows, ~10 hours of processing
    int4_to_int8_copy("events", "id", "id_new")

    # GitLab.com: ~210M rows, ~2 hours of processing
    int4_to_int8_copy("push_event_payloads", "event_id", "event_id_new")
  end

  def down
    # nothing here
  end
end
