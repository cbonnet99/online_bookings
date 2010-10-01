class NonWorkingBooking
  attr_accessor :id, :title, :start_time, :end_time, :read_only
  def initialize(id, title, start_time, end_time, read_only)
    @id = id
    @title = title
    @start_time = start_time
    @end_time = end_time
    @read_only = read_only
  end

  def duration_mins
    (@end_time - @start_time)/60
  end
  
  def to_json(options={})
    %({"id": "#{@id}", "title": "#{@title}", "start": "#{@start_time.iso8601}", "end": "#{@end_time.iso8601}", "readOnly": #{@read_only}, "state": ""})
  end
  
  def to_ics
    booking = Icalendar::Event.new
    booking.start = @start_time.strftime("%Y%m%dT%H%M%S")
    booking.end = @end_time.strftime("%Y%m%dT%H%M%S")
    booking.summary = @title
    booking.description = ""
    booking.location = ''
    booking.klass = "PUBLIC"
    booking.created = Time.zone.now
    booking.last_modified = Time.zone.now
    booking.uid = booking.url = "#{@id}"
    booking
  end
end

class Booking < ActiveRecord::Base
  include AASM
  
  belongs_to :practitioner
  belongs_to :client
  has_many :user_emails, :dependent => :delete_all
  belongs_to :booking_type
  has_many :reminders, :dependent => :delete_all

  validates_presence_of :practitioner, :starts_at, :ends_at, :client
  
  attr_accessible :starts_at, :ends_at, :name, :comment, :booking_type, :booking_type_id, :client_id, :client, :practitioner, :practitioner_id
  attr_accessor :current_client, :current_pro
  
  before_destroy :check_in_grace_period
  after_create :save_client_name, :update_relations_after_create, :send_invite, :create_reminder
  after_destroy :update_relations_after_destroy, :remove_reminders
  after_update :save_client_name
  before_update :set_times
  before_create :generate_confirmation_code, :set_name, :set_times

  named_scope :need_pro_reminder, lambda { {:conditions => ["pro_reminder_sent_at IS NULL AND starts_at BETWEEN ? AND ?", 1.day.from_now.beginning_of_day.utc, 1.day.from_now.end_of_day.utc]} }

  PREP_LABEL = "prep-"
  GRACE_PERIOD_IN_HOURS = 1
  
  aasm_column :state

  aasm_initial_state :new_booking

  aasm_state :new_booking
  aasm_state :confirmed, :enter => [:remove_reminders, :set_confirmed_at]
  aasm_state :cancelled, :enter => [:remove_reminders, :send_cancellation_notice]
    
  aasm_event :confirm do
    transitions :from => :new_booking, :to => :confirmed
  end

  aasm_event :cancel do
    transitions :from => [:new_booking, :confirmed], :to => :cancelled
  end
  
  def set_confirmed_at
    self.update_attribute(:confirmed_at, Time.now)
  end
  
  def send_cancellation_notice
    unless self.in_grace_period?
      UserEmail.create(:to => self.client.email, :from => APP_CONFIG[:from_email], :client => self.client, :practitioner => self.practitioner,
       :subject => I18n.t(:your_booking_was_cancelled, :pro_name => self.practitioner.name), :email_type => UserEmail::CANCELLATION_NOTICE, :delay_mins => 0)
    end
  end
  
  def check_in_grace_period
    raise ActiveRecord::RecordNotSaved unless self.in_grace_period?
  end
  
  def in_grace_period?
    new_booking? && created_at > GRACE_PERIOD_IN_HOURS.hours.ago
  end
  
  def remove_reminders
    self.reminders.destroy_all
  end
  
  def create_reminder
    Reminder.create(:booking => self, :sending_at => starts_at.advance(:days => -1))
  end
  
  def set_defaults(current_client, current_pro, client, pro)
    self.current_client = current_client
    self.current_pro = current_pro
    self.name = client.try(:default_name) if self.name.blank?
    self.client_id = client.try(:id)
    self.practitioner_id = pro.try(:id)
  end
  
  def prep
    if self.prep_time_mins > 0 && !self.client.nil?
      if self.prep_before?
        start_time = self.starts_at.advance(:minutes => -self.prep_time_mins)
        end_time = self.starts_at
      else
        start_time = self.ends_at
        end_time = self.ends_at.advance(:minutes => self.prep_time_mins)
      end
      return NonWorkingBooking.new("#{Booking::PREP_LABEL}#{self.id}", !self.current_pro.nil? || self.current_pro == self.practitioner ? I18n.t(:prep_time) : I18n.t(:appt_booked), start_time, end_time, true)
    else
      return nil
    end    
  end
  
  def send_invite
    unless self.client.nil?
      if !current_client.nil? && self.client == current_client && self.practitioner.invite_on_client_book?      
        UserEmail.create(:to => self.practitioner.email, :from => APP_CONFIG[:from_email], :client => self.client, :practitioner => self.practitioner,  
         :subject => I18n.t(:client_booking, :client_name => self.client.name, :booking_date => self.start_date.day_and_time), :email_type => UserEmail::PRO_INVITE, :delay_mins => GRACE_PERIOD_IN_HOURS*60)
      end
      if !current_pro.nil? && self.practitioner == current_pro  && self.practitioner.invite_on_pro_book?     
         UserEmail.create(:to => self.client.email, :from => APP_CONFIG[:from_email], :client => self.client, :practitioner => self.practitioner,
          :subject => I18n.t(:pro_booking, :pro_name => self.practitioner.name, :booking_date => self.start_date.day_and_time), :email_type => UserEmail::CLIENT_INVITE, :delay_mins => GRACE_PERIOD_IN_HOURS*60)
      end
    end
  end
    
  def state_color
    case state
    when "confirmed":
      "#0C6"
    when "new_booking":
      "#bf0000"
    else
      "grey"
    end
  end

  def update_relations_after_create
    unless self.client.nil?
      first_appointment_with_this_client = (self.client.bookings.find_all_by_practitioner_id(self.practitioner_id).size == 1)
      if first_appointment_with_this_client
        if self.client.relations.find_by_practitioner_id(self.practitioner_id).nil?
          Relation.create(:practitioner_id => self.practitioner_id, :client_id => self.client_id )
        end
      end
    end
  end

  def update_relations_after_destroy
    unless self.client.nil?
      last_appointment_with_this_client = (self.client.bookings.find_all_by_practitioner_id(self.practitioner_id).size == 0)
      if last_appointment_with_this_client
        self.client.relations.find_by_practitioner_id(self.practitioner_id).try(:destroy)
      end
    end
  end

  def mark_as_pro_reminder_sent!
    update_attribute(:pro_reminder_sent_at, Time.zone.now)
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
  
  def send_reminder_email!
    UserMailer.deliver_booking_reminder(self)
  end

  def generate_confirmation_code
    unless client.nil?
      self.confirmation_code = Digest::SHA256.hexdigest(self.name+Time.zone.now.to_s)
    end
  end

  def self.need_reminders
    res = []
    Practitioner.all.each do |p|
      res += p.bookings_need_reminders
    end
    return res
  end
  
  def start_date_and_time_str
    # "on #{self.start_date_str} at #{self.start_time_str}"
    
    I18n.t(:date_and_time, :scope=>[:time], :date => "#{self.start_date_str}" , :time => "#{self.start_time_str}")
    
  end
  def start_date
    self.starts_at
  end
  def start_date_str
    "#{self.starts_at.strftime('%A %d %B %Y')}"
  end
  
  def start_time_str
    "#{self.starts_at.simple_time}"
    
  end
  def start_time
    self.starts_at
    
  end
 
  def to_ics_with_client_invite
    to_ics(true, false)
  end
  
  def to_ics_with_pro_invite
    to_ics(false, true)
  end
  
  def to_ics(client_invite=false, pro_invite=false)
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
    if client_invite
      params = {"CN" => "\"#{self.practitioner.name}\""}
      booking.organizer "mailto:#{self.practitioner.email}", params
      
      params = {"CN" => "\"#{self.practitioner.name}\"", "CUTYPE" => "INDIVIDUAL", "PARTSTAT" => "ACCEPTED"}
      booking.add_attendee "mailto:#{self.practitioner.email}", params
      
      params = {"CN" => "\"#{self.client.name}\"", "CUTYPE" => "INDIVIDUAL", "PARTSTAT" => "NEEDS-ACTION", "RSVP" => "TRUE"}
      booking.add_attendee "mailto:#{self.client.email}", params
    else
      if pro_invite
        params = {"CN" => "\"#{self.client.name}\""}
        booking.organizer "mailto:#{self.client.email}", params

        params = {"CN" => "\"#{self.client.name}\"", "CUTYPE" => "INDIVIDUAL", "PARTSTAT" => "ACCEPTED"}
        booking.add_attendee "mailto:#{self.client.email}", params

        params = {"CN" => "\"#{self.practitioner.name}\"", "CUTYPE" => "INDIVIDUAL", "PARTSTAT" => "NEEDS-ACTION", "RSVP" => "TRUE"}
        booking.add_attendee "mailto:#{self.practitioner.email}", params
      else
        booking.add_attendee self.client.name
        booking.add_attendee self.practitioner.name
      end
    end
    booking
  end

  def save_client_name
    if !client.nil? && !self.name.blank?
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
      I18n.t(:appt_booked)
    else
      name
    end
  end
  
  def start
    #  "2009-05-03T12:15:00.000+1000"
    
    starts_at.nil? ? nil : starts_at.strftime("%Y-%m-%dT%H:%M:%S.000%z")
  end
  
  def end
    ends_at.nil? ? nil : ends_at.strftime("%Y-%m-%dT%H:%M:%S.000%z")
  end
  
  def locked
    locked?
  end
  
  def locked?
    !in_grace_period?
  end
  
  def client_name
    client.try(:name)
  end
  
  def to_json(options={})
    super options.merge(:only => [:id, :client_id, :client_name, :booking_type_id], :methods => [:locked, :title, :start, :end, :readOnly, :state, :needs_warning, :errors])
  end

  def needs_warning
    needs_warning?
  end

  def needs_warning?
     new_booking? && starts_at > Time.now.in_time_zone(practitioner.timezone) && starts_at < Time.now.in_time_zone(practitioner.timezone).advance(:hours => practitioner.no_cancellation_period_in_hours)
  end
  
  def duration_mins
    (ends_at - starts_at)/60
  end
  
  private
  
  def set_times
    if !self.booking_type.nil? && self.duration_mins != self.booking_type.duration_mins
      self.ends_at = self.starts_at.advance(:minutes => self.booking_type.duration_mins )
    end
    if !self.practitioner.nil? && !self.practitioner.prep_time_mins.nil? && self.practitioner.prep_time_mins > 0
      self.prep_before = self.practitioner.prep_before
      self.prep_time_mins = self.practitioner.prep_time_mins
    end
  end
  
  def set_name
    if client.nil? && name.blank?
      self.state = "confirmed"
      if comment.blank?
        self.name = practitioner.try(:own_time_label)
      else
        self.name = self.comment
      end
    end
  end
  
  
  
end
