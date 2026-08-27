class AddUniqueIndexToCartItemsQuery < ActiveRecord::Migration[8.1]
  def up
    # Remove duplicatas antes de criar o índice único.
    # Mantém o menor id por (cart_id, query) e deleta o resto (com suas seleções).
    execute <<~SQL
      DELETE FROM cart_selections
      WHERE cart_item_id NOT IN (
        SELECT MIN(id) FROM cart_items GROUP BY cart_id, query
      )
    SQL

    execute <<~SQL
      DELETE FROM cart_items
      WHERE id NOT IN (
        SELECT MIN(id) FROM cart_items GROUP BY cart_id, query
      )
    SQL

    add_index :cart_items, [ :cart_id, :query ], unique: true
  end

  def down
    remove_index :cart_items, [ :cart_id, :query ]
  end
end
