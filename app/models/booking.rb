NonWorkingBooking = Struct.new(:id, :title, :start_time, :end_time, :read_only) do
  def to_json(options={})
    %({"id": "#{id}", "title": "#{title}", "start": "#{start_time}", "end": "#{end_time}", "readOnly": #{read_only}})
  end
end

class Booking < ActiveRecord::Base
  belongs_to :practitioner
  belongs_to :client

  validates_presence_of :name
  
  attr_accessible :starts_at, :ends_at, :name, :comment, :booking_type
  attr_accessor :current_client
  
  def include_root_in_json
    false
  end

  def readOnly
    read_only?
  end
  
  def read_only?
    current_client.nil? || current_client.id != client_id
  end
  
  def title
    if read_only?
      "Booked"
    else
      name
    end
  end
  
  def start
    starts_at
  end
  
  def end
    ends_at
  end
  
  def to_json(options={})
    super options.merge(:only => [:id], :methods => [:title, :start, :end, :readOnly, :errors])
  end
end
