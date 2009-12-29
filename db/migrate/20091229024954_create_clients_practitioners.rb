class CreateClientsPractitioners < ActiveRecord::Migration
  def self.up
    create_table :clients_practitioners do |t|
      t.integer :practitioner_id
      t.integer :client_id

      t.timestamps
    end
  end

  def self.down
    drop_table :clients_practitioners
  end
end
