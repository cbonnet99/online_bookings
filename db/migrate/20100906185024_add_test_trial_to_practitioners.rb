class AddTestTrialToPractitioners < ActiveRecord::Migration
  def self.up
    add_column :practitioners, :test_user, :boolean, :default => false 
    add_column :practitioners, :trial, :boolean, :default => true 
  end

  def self.down
    remove_column :practitioners, :trial
    remove_column :practitioners, :test_user
  end
end
