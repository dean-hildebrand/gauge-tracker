# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_07_22_112313) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "gauges", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "created_by_id", null: false
    t.date "ends_on", null: false
    t.string "name", null: false
    t.date "starts_on", null: false
    t.integer "time_unit", default: 2, null: false
    t.string "unit", default: "kWh", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_gauges_on_created_by_id"
    t.check_constraint "ends_on > starts_on", name: "gauges_date_order_check"
    t.check_constraint "time_unit >= 0 AND time_unit <= 3", name: "gauges_time_unit_range_check"
  end

  create_table "readings", force: :cascade do |t|
    t.datetime "approved_at"
    t.bigint "approved_by_id"
    t.datetime "created_at", null: false
    t.bigint "entered_by_id", null: false
    t.bigint "gauge_id", null: false
    t.date "period_start", null: false
    t.datetime "updated_at", null: false
    t.decimal "value", precision: 12, scale: 3, null: false
    t.index ["approved_at"], name: "index_readings_on_approved_at"
    t.index ["approved_by_id"], name: "index_readings_on_approved_by_id"
    t.index ["entered_by_id"], name: "index_readings_on_entered_by_id"
    t.index ["gauge_id", "period_start"], name: "index_readings_on_gauge_id_and_period_start", unique: true
    t.index ["gauge_id"], name: "index_readings_on_gauge_id"
    t.check_constraint "approved_at IS NULL AND approved_by_id IS NULL OR approved_at IS NOT NULL AND approved_by_id IS NOT NULL", name: "readings_approval_pair_check"
    t.check_constraint "value >= 0::numeric", name: "readings_value_non_negative_check"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "name", null: false
    t.datetime "remember_created_at"
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "gauges", "users", column: "created_by_id"
  add_foreign_key "readings", "gauges", on_delete: :cascade
  add_foreign_key "readings", "users", column: "approved_by_id"
  add_foreign_key "readings", "users", column: "entered_by_id"
end
