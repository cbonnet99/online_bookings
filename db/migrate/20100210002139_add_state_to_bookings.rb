class AddStateToBookings < ActiveRecord::Migration
  def self.up
    add_column :bookings, :state, :string
  end

  def self.down
    remove_column :bookings, :state
  end
end
