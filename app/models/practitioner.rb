class ProStub
  attr_accessor :name
  def initialize(name)
    @name = name
  end
end

class BlankEmailsException < Exception
end

class InvalidEmailsException < Exception
end

class Practitioner < ActiveRecord::Base
  include Permalinkable
  
  has_many :bookings
  has_many :relations
  has_many :clients, :through => :relations

  # new columns need to be added here to be writable through mass assignment
  attr_accessible :username, :email, :password, :password_confirmation, :working_hours, :working_days, :first_name, :last_name, :phone, :no_cancellation_period_in_hours
  
  attr_accessor :password
  before_save :prepare_password
  
  validates_presence_of :working_hours, :phone, :no_cancellation_period_in_hours
  validates_format_of :working_hours, :with => /\-/, :message => "should contain at least one dash to denote start and end times"
  validates_format_of :username, :with => /^[-\w\._@]+$/i, :allow_blank => true, :message => "should only contain letters, numbers, or .-_@"
  validates_format_of :email, :with => /^[-a-z0-9_+\.]+\@([-a-z0-9]+\.)+[a-z0-9]{2,4}$/i
  validates_presence_of :password, :on => :create
  validates_confirmation_of :password
  validates_length_of :password, :minimum => 4, :allow_blank => true
  validates_uniqueness_of :email
  
  named_scope :want_reminder_night_before, :conditions => "reminder_night_before IS true"
  
  TITLE_FOR_NON_WORKING = "Booked"

  def add_clients(emails_string, send_email, email_text, email_signoff)
    emails = emails_string.gsub(/\,/, " ").split(" ")
    invalid_emails = []
    if emails.blank?
      raise BlankEmailsException
    else
      emails.each do |email|
        unless email.match(/^[-a-z0-9_+\.]+\@([-a-z0-9]+\.)+[a-z0-9]{2,4}$/i)
          invalid_emails << email
        end
      end
      if invalid_emails.blank?
        emails.each do |email|
          unless self.clients.find_by_email(email)
            existing_client = Client.find_by_email(email)
            if existing_client
              self.clients << existing_client
            else
              client = self.clients.create(:email => email)
              UserMailer.deliver_initial_client_email(self, client, email_text, email_signoff) if send_email
            end
          end
        end
      else
        raise InvalidEmailsException.new(invalid_emails.to_sentence)
      end
    end
  end

  def self.need_reminders
    Practitioner.want_reminder_night_before.reject{|p| p.bookings.need_pro_reminder.blank?}
  end
  
  def send_reminder!
    UserMailer.deliver_booking_pro_reminder(self)
    self.bookings.need_pro_reminder.each {|b| b.mark_as_pro_reminder_sent!}
  end
  

  def update_booking(booking, hash_booking, current_pro)
    booking.practitioner_id = current_pro.id
    booking.current_pro = current_pro
    unless hash_booking["client_id"].nil?
      client = Client.find(hash_booking["client_id"])
      booking.name = client.default_name
    end
    hash_booking.delete("practitioner_id")
    hash_booking.delete("name")
    return booking, hash_booking
  end

  def toggle_bookings_publish_code
    if bookings_publish_code.blank?
      generate_bookings_publish_code
    else
      self.update_attribute(:bookings_publish_code, nil)
    end
  end

  def generate_bookings_publish_code
    self.update_attribute(:bookings_publish_code, Digest::SHA256.hexdigest(self.email+Time.now.to_s)[0..11])
  end

  def clients_options
    res = []
    clients.map do |c|
      res << [c.name, c.id]
    end
    return res
  end
  
  def calendar_title(current_pro)
    # if (current_pro == self)
      self.name
    # else
    #   "Step 3: book your appointment with #{self.name}"
    # end    
  end

  def biz_hours_start
    TimeUtils.round_previous_hour(working_hours.split("-").first)
  end
  
  def biz_hours_end
    TimeUtils.round_next_hour(working_hours.split("-").last)
  end

  def own_bookings(start_timestamp=nil, end_timestamp=nil)
    start_time = if start_timestamp.blank?
      Time.now.beginning_of_week
    else
      Time.at(start_timestamp)
    end
    end_time = if end_timestamp.blank?
      Time.now.end_of_week
    else
      Time.at(end_timestamp)
    end
    raw_own_bookings = Booking.find_all_by_practitioner_id(self.id, :conditions => ["state <> ? AND starts_at BETWEEN ? AND ?", "cancelled", start_time, end_time] )
    raw_own_bookings.each do |b|
      b.current_pro = self
    end
    raw_own_bookings + bookings_for_non_working_days(start_time, end_time) + bookings_for_working_hours(start_time, end_time)
  end
  
  def all_bookings(current_client=nil, start_timestamp=nil, end_timestamp=nil)
    start_time = if start_timestamp.blank?
      Time.now.beginning_of_week
    else
      Time.at(start_timestamp)
    end
    end_time = if end_timestamp.blank?
      Time.now.end_of_week
    else
      Time.at(end_timestamp)
    end
    client_bookings(current_client, start_time, end_time) + bookings_for_non_working_days(start_time, end_time) + bookings_for_working_hours(start_time, end_time)
  end
  
  def client_bookings(current_client, start_time, end_time)
    raw_bookings = Booking.find_all_by_practitioner_id(self.id, :conditions => ["state <> ? AND starts_at BETWEEN ? AND ?", "cancelled", start_time, end_time] )
    raw_bookings.each {|rb| rb.current_client = current_client}
  end
  
  def show_days
    if works_weekends?
      7
    else
      5
    end
  end
  
  def works_weekends?
    !working_days.blank? && (working_days.include?("6") || working_days.include?("7"))
  end
  
  def bookings_for_non_working_days(start_time, end_time)
    current = start_time
    res = []
    while current < end_time
      day, month, year, week_day = current.strftime("%d %m %Y %w").split(" ")
      if !working_days.blank? && !working_days.include?(week_day)
        res << NonWorkingBooking.new("#{self.id}-#{day}-#{month}-#{year}", TITLE_FOR_NON_WORKING, Time.parse("#{year}/#{month}/#{day} #{biz_hours_start}"), Time.parse("#{year}/#{month}/#{day} #{biz_hours_end}"), true)
      end
      current += 1.day
    end
    res
  end
  
  def bookings_for_working_hours(start_time, end_time)
    res = []
    current = start_time
    while current < end_time
      day, month, year, week_day = current.strftime("%d %m %Y %w").split(" ")
      if !working_days.blank? && working_days.include?(week_day)
        split_hours = working_hours.split(",")
        split_hours.each_with_index do |str, i|
          slot_start_time = str.split("-").try(:last)
          if slot_start_time.nil?
            raise "There is a format error on working hours for practitioner #{self.name}: #{self.working_hours} [start time for #{str}]"
          end
          is_last_entry = (i >= split_hours.size-1)
          if is_last_entry
            slot_end_time = self.biz_hours_end
          else
            slot_end_time = split_hours[i+1].split("-").try(:first)
          end            
          if slot_end_time.nil?
            raise "There is a format error on working hours for practitioner #{self.name}: #{self.working_hours} [end time for #{split_hours[i+1]}]"
          end
          if slot_end_time > slot_start_time
            res << NonWorkingBooking.new("#{self.id}-#{day}-#{month}-#{year}-#{slot_start_time}", TITLE_FOR_NON_WORKING, Time.parse("#{year}/#{month}/#{day} #{TimeUtils.fix_minutes(slot_start_time)}"), Time.parse("#{year}/#{month}/#{day} #{TimeUtils.fix_minutes(slot_end_time)}"), true)
          end
        end
      end
      current += 1.day
    end
    res
  end
  
  # login can be either username or email address
  def self.authenticate(login, pass)
    practitioner = find_by_username(login) || find_by_email(login)
    return practitioner if practitioner && practitioner.matching_password?(pass)
  end
  
  def name
    "#{first_name} #{last_name}"
  end
  
  def matching_password?(pass)
    self.password_hash == encrypt_password(pass)
  end
  
  private
  
  def prepare_password
    unless password.blank?
      self.password_salt = Digest::SHA1.hexdigest([Time.now, rand].join)
      self.password_hash = encrypt_password(password)
    end
  end
  
  def encrypt_password(pass)
    Digest::SHA1.hexdigest([pass, password_salt].join)
  end
end
