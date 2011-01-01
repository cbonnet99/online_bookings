class AddCurrencyToPayments < ActiveRecord::Migration
  def self.up
    add_column :payments, :currency, :string
  end

  def self.down
    remove_column :payments, :currency
  end
end
