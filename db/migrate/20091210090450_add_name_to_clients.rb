class AddNameToClients < ActiveRecord::Migration
  def self.up
    add_column :clients, :first_name, :string
    add_column :clients, :last_name, :string
  end

  def self.down
    remove_column :clients, :last_name
    remove_column :clients, :first_name
  end
end
