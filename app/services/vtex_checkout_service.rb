class VtexCheckoutService
  def initialize(site_url)
    @site_url = site_url
  end

  def checkout_url(selections)
    items = selections.map { |s| "sku=#{s.sku_id}&qty=1&seller=1" }.join("&")
    "#{@site_url}/checkout/cart/add?#{items}"
  end
end
