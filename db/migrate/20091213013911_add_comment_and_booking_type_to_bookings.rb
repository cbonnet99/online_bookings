class AddCommentAndBookingTypeToBookings < ActiveRecord::Migration
  def self.up
    add_column :bookings, :comment, :text
    add_column :bookings, :booking_type, :string
  end

  def self.down
    remove_column :bookings, :booking_type
    remove_column :bookings, :comment
  end
end
