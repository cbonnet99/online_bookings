class CreatePaymentPlans < ActiveRecord::Migration
  def self.up
    create_table :payment_plans do |t|
      t.integer :amount
      t.string :title
      t.text :description
      t.integer :country_id

      t.timestamps
    end
  end

  def self.down
    drop_table :payment_plans
  end
end
