class AddPhoneToPractitioners < ActiveRecord::Migration
  def self.up
    add_column :practitioners, :phone, :string
  end

  def self.down
    remove_column :practitioners, :phone
  end
end
