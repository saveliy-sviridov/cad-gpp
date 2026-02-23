# frozen_string_literal: true

class CreateProcedureMirrors < ActiveRecord::Migration[7.2]
  def change
    create_table :procedure_mirrors do |t|
      t.string :public_instance_url, null: false
      t.string :public_procedure_graphql_id
      t.integer :public_procedure_number, null: false
      t.references :procedure, null: false, foreign_key: true
      t.datetime :last_synced_at
      t.integer :auto_sync_frequency

      t.timestamps
    end

    add_index :procedure_mirrors, [:public_instance_url, :public_procedure_number], unique: true, name: 'index_procedure_mirrors_on_url_and_number'
  end
end
