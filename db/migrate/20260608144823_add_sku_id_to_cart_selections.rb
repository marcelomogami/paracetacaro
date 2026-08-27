class AddSkuIdToCartSelections < ActiveRecord::Migration[8.1]
  def change
    add_column :cart_selections, :sku_id, :string
  end
end
