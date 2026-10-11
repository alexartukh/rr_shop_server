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

ActiveRecord::Schema[8.1].define(version: 0) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "items", force: :cascade do |t|
    t.string "name", limit: 255, null: false
    t.text "description"
    t.decimal "price", precision: 10, scale: 2, null: false
    t.datetime "created_at", default: -> { "now()" }, null: false
    t.datetime "updated_at", default: -> { "now()" }, null: false
    t.check_constraint "price >= 0::numeric", name: "items_price_check"
  end

  create_table "orders", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.decimal "amount", precision: 12, scale: 2, default: "0.0", null: false
    t.datetime "created_at", default: -> { "now()" }, null: false
    t.datetime "updated_at", default: -> { "now()" }, null: false
    t.index ["user_id"], name: "index_orders_on_user_id"
    t.check_constraint "amount >= 0::numeric", name: "orders_amount_check"
  end

  create_table "orders_description", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "item_id", null: false
    t.integer "quantity", null: false
    t.datetime "created_at", default: -> { "now()" }, null: false
    t.datetime "updated_at", default: -> { "now()" }, null: false
    t.index ["item_id"], name: "index_orders_description_on_item_id"
    t.check_constraint "quantity > 0", name: "orders_description_quantity_check"
    t.unique_constraint ["order_id", "item_id"], name: "orders_description_order_id_item_id_key"
  end

  create_table "users", force: :cascade do |t|
    t.string "first_name", limit: 100, null: false
    t.string "last_name", limit: 100, null: false
    t.string "email", limit: 255, null: false
    t.string "encrypted_password", limit: 255, default: "", null: false
    t.string "role", limit: 10, default: "USER", null: false
    t.string "jti", limit: 255, default: -> { "(gen_random_uuid())::text" }, null: false
    t.datetime "created_at", default: -> { "now()" }, null: false
    t.datetime "updated_at", default: -> { "now()" }, null: false
    t.index "lower((email)::text)", name: "index_users_on_lower_email", unique: true
    t.index ["jti"], name: "index_users_on_jti", unique: true
    t.check_constraint "role::text = ANY (ARRAY['ADMIN'::character varying, 'USER'::character varying]::text[])", name: "users_role_check"
  end

  add_foreign_key "orders", "users", name: "orders_user_id_fkey", on_delete: :restrict
  add_foreign_key "orders_description", "items", name: "orders_description_item_id_fkey", on_delete: :restrict
  add_foreign_key "orders_description", "orders", name: "orders_description_order_id_fkey", on_delete: :cascade
end
