require "rails_helper"

RSpec.describe CartSelection, type: :model do
  it { is_expected.to belong_to(:cart_item) }
  it { is_expected.to validate_presence_of(:pharmacy_slug) }
  it { is_expected.to validate_presence_of(:pharmacy_name) }
  it { is_expected.to validate_presence_of(:nome) }
  it { is_expected.to validate_presence_of(:url) }
  it { is_expected.to validate_numericality_of(:preco).is_greater_than_or_equal_to(0) }

  it "não permite duas seleções da mesma farmácia no mesmo item" do
    item = create(:cart_item)
    create(:cart_selection, cart_item: item, pharmacy_slug: "paguemenos")
    duplicate = build(:cart_selection, cart_item: item, pharmacy_slug: "paguemenos")
    expect(duplicate).not_to be_valid
  end
end
