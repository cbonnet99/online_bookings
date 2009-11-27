class CreateBookings < ActiveRecord::Migration
  def self.up
    create_table :bookings do |t|
      t.datetime :starts_at
      t.datetime :ends_at
      t.string :name
      t.integer :client_id
      t.timestamps
    end
  end
  
  def self.down
    drop_table :bookings
  end
end
