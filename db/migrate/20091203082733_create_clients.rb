class CreateClients < ActiveRecord::Migration
  def self.up
    create_table :clients do |t|
      t.string :email
      t.string :password_hash
      t.string :password_salt
      t.string :question, :limit => 500 
      t.string :answer, :string
      t.timestamps
    end
  end
  
  def self.down
    drop_table :clients
  end
end
