class CartItem < ApplicationRecord
  belongs_to :cart
  has_many :cart_selections, dependent: :destroy

  before_validation { self.query = query.to_s.downcase.strip }

  validates :query, presence: true, uniqueness: { scope: :cart_id }

  def selection_for(pharmacy_slug)
    cart_selections.find_by(pharmacy_slug: pharmacy_slug)
  end

  def ideal_selection
    cart_selections.min_by(&:preco)
  end
end
