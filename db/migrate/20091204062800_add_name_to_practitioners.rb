class AddNameToPractitioners < ActiveRecord::Migration
  def self.up
    add_column :practitioners, :first_name, :string
    add_column :practitioners, :last_name, :string
  end

  def self.down
    remove_column :practitioners, :last_name
    remove_column :practitioners, :first_name
  end
end
