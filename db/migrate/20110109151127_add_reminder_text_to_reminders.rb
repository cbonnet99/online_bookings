class AddReminderTextToReminders < ActiveRecord::Migration
  def self.up
    add_column :reminders, :reminder_text, :text
  end

  def self.down
    remove_column :reminders, :reminder_text
  end
end
