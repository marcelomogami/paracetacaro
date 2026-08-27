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

ActiveRecord::Schema[8.1].define(version: 2026_06_11_131809) do
  create_table "cart_items", force: :cascade do |t|
    t.integer "cart_id", null: false
    t.datetime "created_at", null: false
    t.string "query", null: false
    t.datetime "updated_at", null: false
    t.index ["cart_id", "query"], name: "index_cart_items_on_cart_id_and_query", unique: true
    t.index ["cart_id"], name: "index_cart_items_on_cart_id"
  end

  create_table "cart_selections", force: :cascade do |t|
    t.integer "cart_item_id", null: false
    t.datetime "created_at", null: false
    t.string "fabricante"
    t.string "imagem"
    t.string "nome", null: false
    t.string "pharmacy_name", null: false
    t.string "pharmacy_slug", null: false
    t.decimal "preco", precision: 10, scale: 2, null: false
    t.decimal "preco_original", precision: 10, scale: 2
    t.string "promocao"
    t.string "sku_id"
    t.datetime "updated_at", null: false
    t.string "url", null: false
    t.index ["cart_item_id", "pharmacy_slug"], name: "index_cart_selections_on_cart_item_id_and_pharmacy_slug", unique: true
    t.index ["cart_item_id"], name: "index_cart_selections_on_cart_item_id"
  end

  create_table "carts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.boolean "beta_tester", default: false, null: false
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "name"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "cart_items", "carts"
  add_foreign_key "cart_selections", "cart_items"
end
