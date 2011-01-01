class AddPaymentPlanToPractitioners < ActiveRecord::Migration
  def self.up
    add_column :practitioners, :payment_plan_id, :integer
  end

  def self.down
    remove_column :practitioners, :payment_plan_id
  end
end
