require "rails_helper"

RSpec.describe VtexCheckoutService do
  let(:site_url) { "https://www.paguemenos.com.br" }
  let(:service) { described_class.new(site_url) }
  let(:selections) do
    [
      instance_double(CartSelection, sku_id: "11111111"),
      instance_double(CartSelection, sku_id: "22222222")
    ]
  end

  describe "#checkout_url" do
    it "retorna a URL do cart/add da farmácia" do
      expect(service.checkout_url(selections)).to start_with("#{site_url}/checkout/cart/add")
    end

    it "inclui todos os sku_ids" do
      url = service.checkout_url(selections)
      expect(url).to include("sku=11111111").and include("sku=22222222")
    end

    it "inclui quantidade para cada item" do
      url = service.checkout_url(selections)
      expect(url.scan("qty=1").size).to eq(2)
    end
  end
end
