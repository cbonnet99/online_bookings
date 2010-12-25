class AddTypeToReminders < ActiveRecord::Migration
  def self.up
    add_column :reminders, :reminder_type, :string
  end

  def self.down
    remove_column :reminders, :reminder_type
  end
end
