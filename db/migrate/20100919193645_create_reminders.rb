class CreateReminders < ActiveRecord::Migration
  def self.up
    create_table :reminders do |t|
      t.integer :booking_id
      t.datetime :sent_at

      t.timestamps
    end
  end

  def self.down
    drop_table :reminders
  end
end
