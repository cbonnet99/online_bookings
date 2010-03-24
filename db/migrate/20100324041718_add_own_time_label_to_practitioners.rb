class AddOwnTimeLabelToPractitioners < ActiveRecord::Migration
  def self.up
    add_column :practitioners, :own_time_label, :string
    execute "UPDATE practitioners SET own_time_label='Own time'"
  end

  def self.down
    remove_column :practitioners, :own_time_label
  end
end
