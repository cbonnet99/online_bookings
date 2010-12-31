class AddSmsCreditToPaymentPlans < ActiveRecord::Migration
  def self.up
    add_column :payment_plans, :sms_credit, :integer, :default => 0 
  end

  def self.down
    remove_column :payment_plans, :sms_credit
  end
end
