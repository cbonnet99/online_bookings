NonWorkingBooking = Struct.new(:id, :title, :start_time, :end_time, :read_only) do
  def to_json(options={})
    %({"id": "#{id}", "title": "#{title}", "start": "#{start_time}", "end": "#{end_time}", "readOnly": #{read_only}})
  end
end

class Booking < ActiveRecord::Base
  belongs_to :practitioner
  belongs_to :client
  
  attr_accessible :starts_at, :ends_at, :client_id
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
    if !current_client.nil? && current_client.id == client_id
      name
    else
      "Booked"
    end
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
