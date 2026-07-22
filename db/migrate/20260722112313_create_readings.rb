class CreateReadings < ActiveRecord::Migration[8.1]
  def change
    create_table :readings do |t|
      t.references :gauge,       null: false, foreign_key: { on_delete: :cascade }
      t.references :entered_by,  null: false, foreign_key: { to_table: :users }
      t.references :approved_by, null: true,  foreign_key: { to_table: :users }
      t.date     :period_start, null: false
      t.decimal  :value, precision: 12, scale: 3, null: false
      t.datetime :approved_at
      t.timestamps
    end

    add_index :readings, [ :gauge_id, :period_start ], unique: true
    add_index :readings, :approved_at

    add_check_constraint :readings, "value >= 0", name: "readings_value_non_negative_check"
    add_check_constraint :readings,
      "(approved_at IS NULL AND approved_by_id IS NULL) OR " \
      "(approved_at IS NOT NULL AND approved_by_id IS NOT NULL)",
      name: "readings_approval_pair_check"
  end
end
