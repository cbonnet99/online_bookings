class AddStatusToPayments < ActiveRecord::Migration
  def self.up
    add_column :payments, :status, :string
  end

  def self.down
    remove_column :payments, :status
  end
end
