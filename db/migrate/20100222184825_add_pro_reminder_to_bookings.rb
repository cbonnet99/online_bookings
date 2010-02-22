class AddProReminderToBookings < ActiveRecord::Migration
  def self.up
    add_column :bookings, :pro_reminder_sent_at, :datetime
  end

  def self.down
    remove_column :bookings, :pro_reminder_sent_at
  end
end
