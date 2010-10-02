class AddCountryCodeToClients < ActiveRecord::Migration
  def self.up
    add_column :clients, :country_code, :string, :limit => 2
    remove_column :practitioners, :country_code
    add_column :practitioners, :country_code, :string, :limit => "2"
  end

  def self.down
    remove_column :clients, :country_code
  end
end
