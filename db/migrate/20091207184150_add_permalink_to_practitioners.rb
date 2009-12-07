class AddPermalinkToPractitioners < ActiveRecord::Migration
  def self.up
    add_column :practitioners, :permalink, :string
  end

  def self.down
    remove_column :practitioners, :permalink
  end
end
