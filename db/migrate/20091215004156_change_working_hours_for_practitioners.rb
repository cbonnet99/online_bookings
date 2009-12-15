class ChangeWorkingHoursForPractitioners < ActiveRecord::Migration
  def self.up
    add_column :practitioners, :working_hours, :string
    execute "UPDATE practitioners SET working_hours = biz_hours_start || ',' || biz_hours_end"
    remove_column :practitioners, :biz_hours_start
    remove_column :practitioners, :biz_hours_end
  end

  def self.down
    add_column :practitioners, :biz_hours_start, :string, :limit => 5  
    add_column :practitioners, :biz_hours_end, :string, :limit => 5
    execute "UPDATE practitioners SET biz_hours_start = SUBSTRING(working_hours from '^(..?),')"
    execute "UPDATE practitioners SET biz_hours_end = SUBSTRING(working_hours from ',(..?)$')"
    remove_column :practitioners, :working_hours
  end
end
