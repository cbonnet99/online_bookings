class AddCardInforToPayments < ActiveRecord::Migration
  def self.up
    add_column :payments, :card_type, :string
    add_column :payments, :card_expires_on, :date
  end

  def self.down
    remove_column :payments, :card_expires_on
    remove_column :payments, :card_type
  end
end
