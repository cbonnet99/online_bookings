class AddSmsCreditToPractitioners < ActiveRecord::Migration
  def self.up
    add_column :practitioners, :sms_credit, :integer, :default => 0 
  end

  def self.down
    remove_column :practitioners, :sms_credit
  end
end
