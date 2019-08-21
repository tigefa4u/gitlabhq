# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddPriorityToCiBuilds < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    add_column :ci_builds, :scheduler_priority, :integer, limit: 2
  end
end
