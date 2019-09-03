# frozen_string_literal: true

class AddProjectPagesSizeLimit < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    add_column :projects, :pages_size_limit, :bigint
  end
end
