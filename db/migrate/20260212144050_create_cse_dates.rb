# frozen_string_literal: true

class CreateCseDates < ActiveRecord::Migration[7.2]
  def change
    create_table :cse_dates do |t|
      t.references :procedure, null: false, foreign_key: true
      t.date :date, null: false

      t.timestamps
    end
  end
end
