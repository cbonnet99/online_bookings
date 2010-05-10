class ExtraWorkingDay < ActiveRecord::Base
  belongs_to :practitioner
  
  validates_presence_of :day_date, :practitioner
  
  attr_accessible :day_date
  
    
  def validate
    if !day_date.nil? && !practitioner.nil?
      if practitioner.working_days_in_timeframe(day_date-1.day, day_date+1.day).include?(day_date)
        self.errors.add(:day_date, "is already a working day")
      end
    end
  end
end
