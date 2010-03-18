class AddBookingToUserEmails < ActiveRecord::Migration
  def self.up
    add_column :user_emails, :booking_id, :integer
  end

  def self.down
    remove_column :user_emails, :booking_id
  end
end
