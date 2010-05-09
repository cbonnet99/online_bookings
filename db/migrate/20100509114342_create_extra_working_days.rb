class CreateExtraWorkingDays < ActiveRecord::Migration
  def self.up
    create_table :extra_working_days do |t|
      t.date :day_date
      t.integer :practitioner_id
      t.timestamps
    end
    add_index :extra_working_days, :practitioner_id
  end

  def self.down
    drop_table :extra_working_days
  end
end
