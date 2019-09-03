# frozen_string_literal: true

class AddNamespacesArtifactsSizeLimit < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    add_column :namespaces, :artifacts_size_limit, :bigint
  end
end
