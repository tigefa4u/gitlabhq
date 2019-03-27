# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class CreatePagesDomainsAcmeOrders < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :pages_domain_acme_orders do |t|
      t.references :pages_domain, null: false, index: true, foreign_key: { on_delete: :cascade }

      t.string :url, null: false
      t.string :finalize_url, null: false
      t.datetime_with_timezone :expires, null: false

      t.string :challenge_token, null: false
      t.text :challenge_file_content, null: false

      t.text :private_key, null: false
      t.timestamps_with_timezone null: false
    end
  end
end
