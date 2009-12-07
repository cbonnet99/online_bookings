class AddPractitionerToBookings < ActiveRecord::Migration
  def self.up
    add_column :bookings, :practitioner_id, :integer
  end

  def self.down
    remove_column :bookings, :practitioner_id
  end
end
