class AddResetCodeToClients < ActiveRecord::Migration
  def self.up
    add_column :clients, :reset_code, :string, :limit => 40 
  end

  def self.down
    remove_column :clients, :reset_code
  end
end
