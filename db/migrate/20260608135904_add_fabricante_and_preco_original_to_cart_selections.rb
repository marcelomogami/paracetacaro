class AddFabricanteAndPrecoOriginalToCartSelections < ActiveRecord::Migration[8.1]
  def change
    add_column :cart_selections, :fabricante, :string
    add_column :cart_selections, :preco_original, :decimal, precision: 10, scale: 2
  end
end
