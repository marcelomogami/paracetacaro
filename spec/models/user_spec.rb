require "rails_helper"

RSpec.describe User, type: :model do
  subject(:user) { build(:user) }

  it { is_expected.to validate_presence_of(:email) }
  it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
  it { is_expected.to validate_presence_of(:password) }
  it { is_expected.to allow_value("user@example.com").for(:email) }
  it { is_expected.not_to allow_value("invalido").for(:email) }
end
