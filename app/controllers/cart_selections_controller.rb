class CartSelectionsController < ApplicationController
  def create
    cart = find_or_create_cart
    item = cart.cart_items.find_or_create_by!(query: params[:query].to_s.downcase.strip)
    selection = item.cart_selections.find_or_initialize_by(pharmacy_slug: params[:pharmacy_slug])
    selection.update!(
      pharmacy_name: params[:pharmacy_name],
      nome: params[:nome],
      preco: params[:preco],
      url: params[:url],
      imagem: params[:imagem].presence,
      fabricante: params[:fabricante].presence,
      preco_original: params[:preco_original].presence,
      sku_id: params[:sku_id].presence,
      promocao: params[:promocao].presence
    )

    @cart = cart
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: root_path }
    end
  end

  def destroy
    CartSelection.find(params[:id]).destroy
    redirect_to cart_path
  end

  private

  def find_or_create_cart
    cart = Cart.find_by(id: session[:cart_id])
    cart ||= Cart.create!
    session[:cart_id] = cart.id
    cart
  end
end
