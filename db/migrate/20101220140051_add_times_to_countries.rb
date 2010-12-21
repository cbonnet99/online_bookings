class AddTimesToCountries < ActiveRecord::Migration
  def self.up
    add_column :countries, :time_slots, :string
    add_column :countries, :default_start_time1, :integer
    add_column :countries, :default_end_time1, :integer
    add_column :countries, :default_start_time2, :integer
    add_column :countries, :default_end_time2, :integer
  end

  def self.down
    remove_column :countries, :default_end_time1
    remove_column :countries, :default_start_time1
    remove_column :countries, :default_end_time2
    remove_column :countries, :default_start_time2
    remove_column :countries, :time_slots
  end
end
