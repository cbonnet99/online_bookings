class AddTimezoneToPractitioners < ActiveRecord::Migration
  def self.up
    add_column :practitioners, :timezone, :string, :default => "Wellington"
    execute "UPDATE practitioners SET timezone='Wellington'" 
  end

  def self.down
    remove_column :practitioners, :timezone
  end
end
