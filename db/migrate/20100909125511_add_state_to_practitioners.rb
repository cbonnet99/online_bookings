class AddStateToPractitioners < ActiveRecord::Migration
  def self.up
    add_column :practitioners, :state, :string
    remove_column :practitioners, :test_user
    remove_column :practitioners, :trial
  end

  def self.down
    add_column :practitioners, :test_user, :boolean
    add_column :practitioners, :trial, :boolean
    remove_column :practitioners, :state
  end
end
