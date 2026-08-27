class CartsController < ApplicationController
  before_action :load_cart_context, only: [ :show, :checkout ]

  def show; end

  def checkout
    pharmacy_slug = params.require(:pharmacy_slug)
    pharmacy = @pharmacies.find { |p| p.slug == pharmacy_slug }
    return redirect_to cart_path, alert: "Farmácia não encontrada." unless pharmacy

    selections = @cart_items
      .filter_map { |item| item.selection_for(pharmacy_slug) }
      .select { |s| s.sku_id.present? }

    return redirect_to cart_path, alert: "Nenhum produto disponível para abrir na #{pharmacy.name}." if selections.empty?

    checkout_url = VtexCheckoutService.new(pharmacy.site_url).checkout_url(selections)
    redirect_to checkout_url, allow_other_host: true
  end

  def destroy
    current_cart&.cart_items.destroy_all
    redirect_to cart_path
  end

  private

  def load_cart_context
    @cart = current_cart
    @cart_items = @cart ? @cart.cart_items.includes(:cart_selections).order(:created_at) : []
    @pharmacies = PharmacyConfig.load_all
  end
end
