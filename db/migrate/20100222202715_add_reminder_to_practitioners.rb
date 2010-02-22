class AddReminderToPractitioners < ActiveRecord::Migration
  def self.up
    add_column :practitioners, :reminder_night_before, :boolean
  end

  def self.down
    remove_column :practitioners, :reminder_night_before
  end
end
