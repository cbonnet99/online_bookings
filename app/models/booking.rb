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
  include AASM
  
  belongs_to :practitioner
  belongs_to :client

  validates_presence_of :name, :client, :practitioner, :starts_at, :ends_at
  
  attr_accessible :starts_at, :ends_at, :name, :comment, :booking_type, :client_id, :client, :practitioner, :practitioner_id
  attr_accessor :current_client, :current_pro
  
  after_create :save_client_name, :update_relations_after_create
  after_destroy :update_relations_after_destroy
  after_update :save_client_name
  before_create :generate_confirmation_code

  named_scope :need_pro_reminder, :conditions => ["pro_reminder_sent_at IS NULL AND starts_at BETWEEN ? AND ?", 1.day.from_now.beginning_of_day, 1.day.from_now.end_of_day]

  aasm_column :state

  aasm_initial_state :unconfirmed

  aasm_state :unconfirmed
  aasm_state :reminder_sent, :enter => :send_reminder_email
  aasm_state :confirmed
  aasm_state :cancelled

  aasm_event :confirm do
    transitions :to => :confirmed, :from => [:unconfirmed, :reminder_sent]
  end

  aasm_event :cancel do
    transitions :to => :cancelled, :from => [:unconfirmed, :reminder_sent]
  end
  
  aasm_event :send_reminder do
    transitions :to => :reminder_sent, :from => [:unconfirmed]
  end

  def state_color
    case state
    when "confirmed":
      "#0C6"
    when "unconfirmed":
      "#bf0000"
    else
      "grey"
    end
  end

  def update_relations_after_create
    first_appointment_with_this_client = (self.client.bookings.find_all_by_practitioner_id(self.practitioner_id).size == 1)
    if first_appointment_with_this_client
      if self.client.relations.find_by_practitioner_id(self.practitioner_id).nil?
        Relation.create(:practitioner_id => self.practitioner_id, :client_id => self.client_id )
      end
    end
  end

  def update_relations_after_destroy
    last_appointment_with_this_client = (self.client.bookings.find_all_by_practitioner_id(self.practitioner_id).size == 0)
    if last_appointment_with_this_client
      self.client.relations.find_by_practitioner_id(self.practitioner_id).try(:destroy)
    end
  end

  def mark_as_pro_reminder_sent!
    update_attribute(:pro_reminder_sent_at, Time.now)
  end

  def partner_name(current_client, current_pro)
    if current_pro.nil?
      self.try(:practitioner).try(:name)
    else
      self.try(:client).try(:name)
    end
  end

  def self.prepare_delete(current_pro, current_client, id)
    if current_pro.nil?
      booking = current_client.bookings.find(id)
    else
      booking = current_pro.bookings.find(id)
    end
    return booking
  end

  def self.prepare_update(current_pro, current_client, current_selected_pro, hash_booking, id)
    if current_pro.nil?
      booking = current_client.bookings.find(id)
      booking, hash_booking = current_client.update_booking(booking, hash_booking, current_client, current_selected_pro)
    else
      booking = current_pro.bookings.find(id)
      booking, hash_booking = current_pro.update_booking(booking, hash_booking, current_pro)      
    end
    return booking, hash_booking
  end
  
  def send_reminder_email
    UserMailer.deliver_booking_reminder(self)
  end

  def generate_confirmation_code
    self.confirmation_code = Digest::SHA256.hexdigest(self.name+Time.now.to_s)
  end

  def self.need_reminders
    Booking.find(:all, :conditions => ["state = ? AND starts_at < ?", "unconfirmed", 1.day.from_now])
  end
  
  def start_date_and_time_str
    "on #{self.start_date_str} at #{self.start_time_str}"
    #t(:date_and_time, :start_date => "#{self.start_date_str}" , :start_time => "#{self.start_time_str}")
    
  end
  
  def start_date_str
    "#{self.starts_at.strftime('%A %d %B %Y')}"
    
  end
  
  def start_time_str
    "#{self.starts_at.simple_time}"
  end
  
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
    super options.merge(:only => [:id, :client_id], :methods => [:title, :start, :end, :readOnly, :state, :errors])
  end
end
