class CreateCartSelections < ActiveRecord::Migration[8.1]
  def change
    create_table :cart_selections do |t|
      t.references :cart_item, null: false, foreign_key: true
      t.string :pharmacy_slug, null: false
      t.string :pharmacy_name, null: false
      t.string :nome, null: false
      t.decimal :preco, precision: 10, scale: 2, null: false
      t.string :url, null: false
      t.string :imagem

      t.timestamps
    end

    add_index :cart_selections, [ :cart_item_id, :pharmacy_slug ], unique: true
  end
end
