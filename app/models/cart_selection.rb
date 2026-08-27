class CartSelection < ApplicationRecord
  belongs_to :cart_item

  validates :pharmacy_slug, :pharmacy_name, :nome, :url, presence: true
  validates :preco, numericality: { greater_than_or_equal_to: 0 }
  validates :pharmacy_slug, uniqueness: { scope: :cart_item_id }
end
