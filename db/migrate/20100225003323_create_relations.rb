class CreateRelations < ActiveRecord::Migration
  def self.up
    create_table :relations do |t|
      t.integer :client_id
      t.integer :practitioner_id

      t.timestamps
    end
    Practitioner.all.each do |p|
      clients = []
      p.bookings.each do |b|
        clients << b.client unless clients.include?(b.client)
      end
      clients.each do |c|
        Relation.create(:client_id => c.id, :practitioner_id => p.id )
      end
    end
  end

  def self.down
    drop_table :relations
  end
end
