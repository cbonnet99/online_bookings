class CreatePractitioners < ActiveRecord::Migration
  def self.up
    create_table :practitioners do |t|
      t.string :username
      t.string :email
      t.string :password_hash
      t.string :password_salt
      t.timestamps
    end
  end
  
  def self.down
    drop_table :practitioners
  end
end
