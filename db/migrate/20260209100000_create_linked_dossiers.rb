# frozen_string_literal: true

class CreateLinkedDossiers < ActiveRecord::Migration[7.2]
  def change
    create_table :linked_dossiers do |t|
      t.references :dossier, null: false, foreign_key: true, index: { unique: true }
      t.string :public_instance_url, null: false
      t.integer :public_dossier_number, null: false
      t.string :public_dossier_graphql_id
      t.string :usager_email
      t.string :usager_nom
      t.string :usager_prenom
      t.string :public_dossier_state
      t.string :usager_civilite

      t.timestamps
    end

    add_index :linked_dossiers, [:public_instance_url, :public_dossier_number], name: 'index_linked_dossiers_on_url_and_number'
  end
end
