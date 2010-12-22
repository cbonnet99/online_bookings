class DropDefaultForTimezone < ActiveRecord::Migration
  def self.up
    change_column_default(:practitioners, :timezone, nil)
  end

  def self.down
    change_column_default(:practitioners, :timezone, "Wellington")
  end
end
