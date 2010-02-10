class AddConfirmationCodeToBookings < ActiveRecord::Migration
  def self.up
    add_column :bookings, :confirmation_code, :string
  end

  def self.down
    remove_column :bookings, :confirmation_code
  end
end
