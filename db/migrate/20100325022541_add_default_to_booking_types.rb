class AddDefaultToBookingTypes < ActiveRecord::Migration
  def self.up
    add_column :booking_types, :is_default, :boolean 
  end

  def self.down
    remove_column :booking_types, :is_default
  end
end
