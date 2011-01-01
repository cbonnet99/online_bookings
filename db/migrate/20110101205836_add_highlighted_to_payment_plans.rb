class AddHighlightedToPaymentPlans < ActiveRecord::Migration
  def self.up
    add_column :payment_plans, :highlighted, :boolean, :default => false 
  end

  def self.down
    remove_column :payment_plans, :highlighted
  end
end
