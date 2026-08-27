class AddBetaTesterToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :beta_tester, :boolean, default: false, null: false
  end
end
