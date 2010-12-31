class AddProIdToPayments < ActiveRecord::Migration
  def self.up
    add_column :payments, :practitioner_id, :integer
  end

  def self.down
    remove_column :payments, :practitioner_id
  end
end
