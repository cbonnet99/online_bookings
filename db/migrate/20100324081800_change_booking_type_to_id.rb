class ChangeBookingTypeToId < ActiveRecord::Migration
  def self.up
    remove_column :bookings, :booking_type
    add_column :bookings, :booking_type_id, :integer
  end

  def self.down
    remove_column :bookings, :booking_type_id
    add_column :bookings, :booking_type, :string
  end
end
