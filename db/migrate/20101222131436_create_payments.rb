class CreatePayments < ActiveRecord::Migration
  def self.up
    create_table :payments do |t|
      t.integer :payment_plan_id
      t.integer :amount
      t.string :address1
      t.string :city
      t.string :zip
      t.string :state

      t.timestamps
    end
  end

  def self.down
    drop_table :payments
  end
end
