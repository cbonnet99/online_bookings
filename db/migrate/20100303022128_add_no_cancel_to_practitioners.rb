class AddNoCancelToPractitioners < ActiveRecord::Migration
  def self.up
    add_column :practitioners, :no_cancellation_period_in_hours, :integer
    Practitioner.all.each do |pro|
      pro.no_cancellation_period_in_hours = 24
      pro.save!
    end
  end

  def self.down
    remove_column :practitioners, :no_cancellation_period_in_hours
  end
end
