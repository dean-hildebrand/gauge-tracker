class DeviseCreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string  :email,              null: false, default: ""
      t.string  :encrypted_password, null: false, default: ""
      t.string  :name,               null: false
      t.integer :role,               null: false, default: 0
      t.datetime :remember_created_at
      t.timestamps null: false
    end

    add_index :users, :email, unique: true
    add_index :users, :role
  end
end
