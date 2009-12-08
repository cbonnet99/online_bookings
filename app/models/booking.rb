class Booking < ActiveRecord::Base
  belongs_to :practitioner
  belongs_to :client
  attr_accessible :starts_at, :ends_at, :client_id

  def include_root_in_json
    false
  end

  def readOnly
    true
  end
  
  def title
    "Booked"
  end
  
  def start
    starts_at
  end
  
  def end
    ends_at
  end
  
  def to_json(options={})
    super options.merge(:only => [], :methods => [:id, :title, :start, :end, :readOnly])
  end
end
