# frozen_string_literal: true

class AddProjectsArtifactsSizeLimit < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    add_column :projects, :artifacts_size_limit, :bigint
  end
end
