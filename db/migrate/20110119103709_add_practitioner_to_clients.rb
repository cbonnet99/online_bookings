class AddPractitionerToClients < ActiveRecord::Migration
  def self.up
    add_column :clients, :practitioner_id, :integer
    drop_table :relations
  end

  def self.down
    remove_column :clients, :practitioner_id
    create_table :relations do |t|
      t.integer :client_id
      t.integer :practitioner_id
      t.timestamps
    end
  end
end
