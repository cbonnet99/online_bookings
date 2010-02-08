class NonWorkingBooking
  attr_accessor :id, :title, :start_time, :end_time, :read_only
  def initialize(id, title, start_time, end_time, read_only)
    @id = id
    @title = title
    @start_time = start_time
    @end_time = end_time
    @read_only = read_only
  end
  
  def to_json(options={})
    %({"id": "#{@id}", "title": "#{@title}", "start": "#{@start_time.iso8601}", "end": "#{@end_time.iso8601}", "readOnly": #{@read_only}})
  end
  
  def to_ics
    booking = Icalendar::Event.new
    booking.start = @start_time.strftime("%Y%m%dT%H%M%S")
    booking.end = @end_time.strftime("%Y%m%dT%H%M%S")
    booking.summary = @title
    booking.description = ""
    booking.location = ''
    booking.klass = "PUBLIC"
    booking.created = Time.now
    booking.last_modified = Time.now
    booking.uid = booking.url = "#{@id}"
    booking.add_comment("BLA")
    booking
  end
end

class Booking < ActiveRecord::Base
  belongs_to :practitioner
  belongs_to :client

  validates_presence_of :name
  
  attr_accessible :starts_at, :ends_at, :name, :comment, :booking_type, :client_id
  attr_accessor :current_client, :current_pro
  
  after_create :save_client_name
  after_update :save_client_name

  def to_ics
    booking = Icalendar::Event.new
    booking.start = self.starts_at.strftime("%Y%m%dT%H%M%S")
    booking.end = self.ends_at.strftime("%Y%m%dT%H%M%S")
    booking.summary = self.name
    booking.description = self.comment
    booking.location = ''
    booking.klass = "PUBLIC"
    booking.created = self.created_at
    booking.last_modified = self.updated_at
    # booking.uid = booking.url = "#{edit_practitioner_booking_url(:practitioner_id => self.practitioner.permalink, :id => self.id)}"
    booking.uid = booking.url = "#{self.id}"
    booking.add_comment("")
    booking
  end

  def save_client_name
    if !self.name.blank?
      names = self.name.split(" ")
      client.first_name = names[0]
      client.last_name = names[1..names.size].join(" ")
      client.save!
    end
  end
  
  def include_root_in_json
    false
  end

  def readOnly
    read_only?
  end
  
  def read_only?
    (current_pro.nil? || current_pro.id != practitioner_id) && (current_client.nil? || current_client.id != client_id)
  end
  
  def title
    if read_only?
      "Booked"
    else
      name
    end
  end
  
  def start
    #  "2009-05-03T12:15:00.000+10:00"
    starts_at.strftime("%Y-%m-%dT%H:%M:%S.000%z")
  end
  
  def end
    ends_at.strftime("%Y-%m-%dT%H:%M:%S.000%z")
  end
  
  def to_json(options={})
    super options.merge(:only => [:id], :methods => [:title, :start, :end, :readOnly, :errors])
  end
end
