class AddBizHoursAndWorkingDaysToPractitioners < ActiveRecord::Migration
  def self.up
    add_column :practitioners, :biz_hours_start, :string, :limit => 5 
    add_column :practitioners, :biz_hours_end, :string, :limit => 5
    add_column :practitioners, :working_days, :string, :limit => 20
  end

  def self.down
    remove_column :practitioners, :working_days
    remove_column :practitioners, :biz_hours_end
    remove_column :practitioners, :biz_hours_start
  end
end
