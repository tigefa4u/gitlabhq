# frozen_string_literal: true

class AddNamespacesPagesSizeLimit < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    add_column :namespaces, :pages_size_limit, :bigint
  end
end
