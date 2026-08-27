class AddPromocaoToCartSelections < ActiveRecord::Migration[8.1]
  def change
    add_column :cart_selections, :promocao, :string
  end
end
