# frozen_string_literal: true

class CreateChampNotes < ActiveRecord::Migration[7.2]
  def change
    create_table :champ_notes do |t|
      t.references :champ, null: false, foreign_key: true, index: { unique: true }
      t.text :body
      t.timestamps
    end
  end
end
