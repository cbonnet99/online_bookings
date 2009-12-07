class AddPhoneToClients < ActiveRecord::Migration
  def self.up
    add_column :clients, :phone_prefix, :string, :limit => 3 
    add_column :clients, :phone_suffix, :string, :limit => 10 
  end

  def self.down
    remove_column :clients, :phone_suffix
    remove_column :clients, :phone_prefix
  end
end
