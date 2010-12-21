class AddPhoneTimesToPractitioners < ActiveRecord::Migration
  def self.up
    add_column :practitioners, :phone_prefix, :string
    add_column :practitioners, :phone_suffix, :string
    add_column :practitioners, :lunch_break, :boolean
    add_column :practitioners, :start_time1, :integer
    add_column :practitioners, :end_time1, :integer
    add_column :practitioners, :start_time2, :integer
    add_column :practitioners, :end_time2, :integer
    remove_column :practitioners, :phone
    remove_column :practitioners, :working_hours
  end

  def self.down
    remove_column :practitioners, :end_time2
    remove_column :practitioners, :start_time2
    remove_column :practitioners, :end_time1
    remove_column :practitioners, :start_time1
    remove_column :practitioners, :lunch_break
    remove_column :practitioners, :phone_suffix
    remove_column :practitioners, :phone_prefix
    add_column :practitioners, :working_hours, :string
    add_column :practitioners, :phone, :string
  end
end
