class AddConfirmedAtToBookings < ActiveRecord::Migration
  def self.up
    add_column :bookings, :confirmed_at, :datetime
  end

  def self.down
    remove_column :bookings, :confirmed_at
  end
end
