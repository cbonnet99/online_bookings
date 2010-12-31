class AddCurrencyToCountries < ActiveRecord::Migration
  def self.up
    add_column :countries, :currency, :string
    add_column :countries, :currency_symbol, :string
    add_column :countries, :currency_before, :boolean
  end

  def self.down
    remove_column :countries, :currency_before
    remove_column :countries, :currency_symbol
    remove_column :countries, :currency
  end
end
