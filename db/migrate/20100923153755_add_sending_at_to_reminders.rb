class AddSendingAtToReminders < ActiveRecord::Migration
  def self.up
    add_column :reminders, :sending_at, :datetime
  end

  def self.down
    remove_column :reminders, :sending_at
  end
end
