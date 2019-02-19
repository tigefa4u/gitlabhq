# frozen_string_literal: true

class AddRefspecsToCiBuildsMetadata < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column(:ci_builds_metadata, :refspecs, :text)
  end
end
