class CreateExtraNonWorkingDays < ActiveRecord::Migration
  def self.up
    create_table :extra_non_working_days do |t|
      t.date :day_date
      t.integer :practitioner_id

      t.timestamps
    end
  end

  def self.down
    drop_table :extra_non_working_days
  end
end
