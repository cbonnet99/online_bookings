class AddPrepStuff < ActiveRecord::Migration
  def self.up
    add_column :practitioners, :prep_before, :boolean, :default => false
    add_column :practitioners, :prep_time_mins, :integer, :default => 0 
    add_column :bookings, :prep_before, :boolean, :default => false
    add_column :bookings, :prep_time_mins, :integer, :default => 0 
  end

  def self.down
    remove_column :practitioners, :prep_before
    remove_column :practitioners, :prep_time_mins
    remove_column :bookings, :prep_before
    remove_column :bookings, :prep_time_mins
  end
end
