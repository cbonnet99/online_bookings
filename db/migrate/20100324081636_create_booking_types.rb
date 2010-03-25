class CreateBookingTypes < ActiveRecord::Migration
  def self.up
    create_table :booking_types do |t|
      t.string :title
      t.integer :duration_mins
      t.integer :practitioner_id

      t.timestamps
    end
  end

  def self.down
    drop_table :booking_types
  end
end
