class Cart < ApplicationRecord
  has_many :cart_items, dependent: :destroy

  before_create :set_default_name

  def pharmacy_total(pharmacy_slug)
    items = cart_items.includes(:cart_selections).to_a
    return nil if items.empty?

    selections = items.map { |item| item.selection_for(pharmacy_slug) }
    return nil if selections.any?(&:nil?)

    selections.sum(&:preco)
  end

  def cheapest_pharmacy_slug(slugs)
    totals = slugs.filter_map { |s| [ s, pharmacy_total(s) ] if pharmacy_total(s) }.to_h
    return nil if totals.values.uniq.one?

    totals.min_by { |_, v| v }&.first
  end

  def priciest_pharmacy_slug(slugs)
    totals = slugs.filter_map { |s| [ s, pharmacy_total(s) ] if pharmacy_total(s) }.to_h
    return nil if totals.values.uniq.one?

    totals.max_by { |_, v| v }&.first
  end

  def ideal_total
    cart_items.includes(:cart_selections).sum do |item|
      item.ideal_selection&.preco || 0
    end
  end

  def ideal_pharmacies_count
    cart_items.includes(:cart_selections).flat_map do |item|
      item.ideal_selection&.pharmacy_slug
    end.compact.uniq.count
  end

  private

  def set_default_name
    self.name ||= "Carrinho #{Time.current.strftime('%d/%m/%Y %H:%M')}"
  end
end
