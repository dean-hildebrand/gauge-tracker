class CreateGauges < ActiveRecord::Migration[8.1]
  def change
    create_table :gauges do |t|
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.string  :name,      null: false
      t.date    :starts_on, null: false
      t.date    :ends_on,   null: false
      t.string  :unit,      null: false, default: "kWh"
      t.integer :time_unit, null: false, default: 2
      t.timestamps
    end

    add_check_constraint :gauges, "ends_on > starts_on", name: "gauges_date_order_check"
    add_check_constraint :gauges, "time_unit BETWEEN 0 AND 3", name: "gauges_time_unit_range_check"
  end
end
