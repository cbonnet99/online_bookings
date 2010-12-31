class AddNamesToPayments < ActiveRecord::Migration
  def self.up
    add_column :payments, :first_name, :string
    add_column :payments, :last_name, :string
    add_column :payments, :ip_address, :string
  end

  def self.down
    remove_column :payments, :ip_address
    remove_column :payments, :last_name
    remove_column :payments, :first_name
  end
end
