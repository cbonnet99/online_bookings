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
  include ColibriExceptions
  include AASM
  
  has_many :bookings, :dependent => :delete_all 
  has_many :reminders, :through => :bookings
  has_many :relations
  has_many :clients, :through => :relations
  has_many :user_emails
  has_many :booking_types
  has_many :extra_working_days  
  has_many :extra_non_working_days  
  belongs_to :country

  # new columns need to be added here to be writable through mass assignment
  attr_accessible :username, :email, :password, :password_confirmation, :working_hours, :working_days, :first_name,
   :last_name, :phone, :no_cancellation_period_in_hours, :working_day_monday, :working_day_tuesday, :working_day_wednesday,
    :working_day_thursday, :working_day_friday, :working_day_saturday, :working_day_sunday, :timezone, :country
  
  attr_accessor :password, :working_day_monday, :working_day_tuesday, :working_day_wednesday, :working_day_thursday,
   :working_day_friday, :working_day_saturday, :working_day_sunday
  before_save :prepare_password
  
  validates_presence_of :working_hours, :phone, :no_cancellation_period_in_hours
  validates_format_of :working_hours, :with => /\-/, :message => "should contain at least one dash to denote start and end times"
  validates_format_of :username, :with => /^[-\w\._@]+$/i, :allow_blank => true, :message => "should only contain letters, numbers, or .-_@"
  validates_format_of :email, :with => /^[-a-z0-9_+\.]+\@([-a-z0-9]+\.)+[a-z0-9]{2,4}$/i
  validates_presence_of :password, :on => :create
  validates_presence_of :working_days
  validates_confirmation_of :password
  validates_length_of :password, :minimum => 4, :allow_blank => true
  validates_uniqueness_of :email
  
  named_scope :want_reminder_night_before, :conditions => "reminder_night_before IS true"
  
  before_validation :set_working_days
  
  aasm_column :state
  
  aasm_initial_state :test_user
  
  aasm_state :test_user, :exit => "delete_sample_data!"  
  aasm_state :trial
  aasm_state :active
  aasm_state :cancelled
    
  DEFAULT_CANCELLATION_PERIOD = 24
  TITLE_FOR_NON_WORKING = "Booked"
  #WORKING_DAYS = [I18n.t(:monday),I18n.t(:tuesday) ,I18n.t(:wednesday) , I18n.t(:thursday), I18n.t(:friday),I18n.t(:saturday) ,I18n.t(:sunday) ]
  WORKING_DAYS = ["monday","tuesday" ,"wednesday" , "thursday", "friday","saturday" ,"sunday" ]
  #WORKING_DAYS = Date::DAY_NAMES
  #WORKING_DAYS = I18n.t 'date.day_names' does not work with actul code sunday is first day of the week

  DOMAINS = ["gmail.com", "test.com", "info.org"]
  BOOKING_STATES = ["in_grace_period", "unconfirmed", "confirmed" ,"cancelled_by_client", "cancelled_by_pro"]
  
  def mobile_phone_prefixes
    self.country.mobile_phone_prefixes
  end
  
  def landline_phone_prefixes
    self.country.landline_phone_prefixes
  end
  
  def delete_sample_data!
    if self.test_user?
      self.clients.each do |client|
        if client.relations.blank?
          client.delete
        end
      end
      self.destroy
    else
      raise CantDeleteSampleDataOnNonTestProException
    end
  end
  
  def create_sample_data!(number_clients=30, number_bookings=150)
    if self.test_user?
      clients = []
      possible_mobile_prefixes = self.country.mobile_phone_prefixes
      first_names = self.country.sample_first_names.split(",")
      last_names = self.country.sample_last_names.split(",")
      number_clients.times do
        first_name = first_names[rand(first_names.size)]
        last_name = last_names[rand(last_names.size)]
        all_client_names = clients.map(&:name)
        while (all_client_names.include?("#{first_name} #{last_name}"))
          #puts "#{first_name} #{last_name} is taken, trying again"
          first_name = first_names[rand(first_names.size)]
          last_name = last_names[rand(last_names.size)]
        end
        email = "#{first_name}.#{last_name}@#{DOMAINS[rand(DOMAINS.size)]}"
        client = Client.find_by_email(email)
        if client.nil?
          rand_phone_prefix = possible_mobile_prefixes[rand(possible_mobile_prefixes.size)]
          rand_phone_suffix = "#{rand(9)}#{rand(9)} #{rand(9)}#{rand(9)} #{rand(9)}#{rand(9)} #{rand(9)}#{rand(9)}"
          # puts "+++++ Creating client #{first_name} #{last_name} with email: #{email} and phone: (#{rand_phone_prefix}) #{rand_phone_suffix}"
          client = Client.new(:first_name => first_name, :last_name => last_name, :phone_prefix  => rand_phone_prefix,
              :phone_suffix => rand_phone_suffix, 
              :email => email, :password => first_name[0,2] + last_name[0,2], :password_confirmation => first_name[0,2] + last_name[0,2])
          client.save!
        end
        clients << client
      end
    
      wd_as_numbers = self.working_days_as_numbers
      #appointments in the past
      number_bookings.times do
        days_ago = rand(200)
        date = Time.now.advance(:days => -days_ago).to_date
        while (!wd_as_numbers.include?(date.wday)) do
          #try again if it's not a working day
          days_ago = rand(200)
          date = Time.now.advance(:days => -days_ago).to_date        
        end
        start_hour = rand(10)+8
        starts_at = DateTime.strptime("#{date.strftime('%d/%m/%Y')} #{start_hour}:00 CEST", "%d/%m/%Y %H:%M %Z")
        client = clients[rand(clients.size)]
        # puts "+++++ Creating past booking at #{starts_at} for client #{client.name}, email: #{client.email}, phone: (#{client.phone_prefix}) #{client.phone_suffix}"
        booking = Booking.new(:client => client, :practitioner => self, :name => client.name, :client_phone_prefix => client.phone_prefix, 
            :client_phone_suffix => client.phone_suffix, :client_email => client.email, :starts_at => starts_at, :ends_at  => starts_at.advance(:hours => 1), :state => BOOKING_STATES[rand(BOOKING_STATES.size)])
        booking.save!
        if rand(100) < 50
          booking.confirm!
        end
      end
    
      #appointments in the future
      number_bookings.times do
        days = rand(200)
        date = Time.now.advance(:days => days).to_date
        while (!wd_as_numbers.include?(date.wday)) do
          #try again if it's not a working day
          days_ago = rand(200)
          date = Time.now.advance(:days => days_ago).to_date        
        end
        starts_at = DateTime.strptime("#{date.strftime('%d/%m/%Y')} #{rand(10)+8}:00 CEST", "%d/%m/%Y %H:%M %Z")
        client = clients[rand(clients.size)]
        booking = Booking.new(:client => client, :practitioner => self, :name => client.name, 
            :starts_at => starts_at, :ends_at  => starts_at.advance(:hours => 1), :state => BOOKING_STATES[rand(BOOKING_STATES.size)])
        booking.save!
        if rand(100) < 30
          booking.confirm!
        end
        # puts "+++++ Creating future booking at #{starts_at} for client #{client.name}"
      end
    else
      raise CantCreateSampleDataOnNonTestProException
    end    
  end
  
  def working_days_as_numbers
    if working_days.blank?
      []
    else
      working_days.split(",").map(&:to_i).map{|i| i==7? 0 : i}
    end
  end
  
  def set_working_days
    if working_days.blank? && !WORKING_DAYS.map{|day| self.send("working_day_#{day}".to_sym)}.select{|value| value == true || value.to_s == "1"}.blank?
      res = []
      WORKING_DAYS.each_with_index do |day, index|
        value = self.send("working_day_#{day}".to_sym)
        if  value == true || value.to_s == "1"
          res << (index+1).to_s
        end
      end
      self.working_days = res.join(",")
    end
  end
  
  def add_clients(emails_string, send_email, email_text, email_signoff)
    emails = emails_string.split(",")
    invalid_emails = []
    if emails.blank?
      raise BlankEmailsException
    else
      emails.each do |email|
        email.strip!
        m = email.match(/\"(.*)(\s)*\" \<(.*)\>/)
        if m
          email = m[3]
        end
        if email.nil? || !email.match(/^[-a-z0-9_+\.]+\@([-a-z0-9]+\.)+[a-z0-9]{2,4}$/i)
          invalid_emails << email
        end
        
      end
      if invalid_emails.blank?
        emails.each do |email|
          email.strip!
          m = email.match(/\"(.*)(\s)*\" \<(.*)\>/)
          if m
            name, email = m[1], m[3]
          end
          unless self.clients.find_by_email(email)
            existing_client = Client.find_by_email(email)
            if existing_client
              self.clients << existing_client
              client = existing_client
            else
              client = self.clients.create(:email => email, :name => name)
            end
            # UserMailer.send_later :deliver_initial_client_email, self, client, email_text, email_signoff if send_email
            UserMailer.deliver_initial_client_email(self, client, email_text, email_signoff) if send_email
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
    if hash_booking["client_id"].blank? || hash_booking["client_id"].to_i == 0
      hash_booking["client_id"] = nil
      if hash_booking["comment"].blank?
        booking.name = current_pro.own_time_label
      else
        booking.name = hash_booking["comment"]
      end
    else
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
    self.update_attribute(:bookings_publish_code, Digest::SHA256.hexdigest(self.email+Time.zone.now.to_s)[0..11])
  end

  def clients_options
    res = []
    clients.map do |c|
      if c.name.blank?
        res << [c.email, c.id]
      else
        res << [c.name, c.id]
      end
    end
    return res.sort
  end
  
  def calendar_title
      self.name
  end

  def has_multiple_booking_types?
    self.booking_types.size > 1
  end
  
  def default_booking_length_in_timeslots
    if self.booking_types.try(:first).nil?
      2
    else
      self.booking_types.first.duration_mins/30
    end
  end
    
  def biz_hours_start
    TimeUtils.round_previous_hour(working_hours.split("-").first)
  end
  
  def biz_hours_end
    TimeUtils.round_next_hour(working_hours.split("-").last)
  end

  def raw_own_bookings(start_time, end_time)
    Booking.find_all_by_practitioner_id(self.id, :conditions => ["state <> ? AND state <> ? AND starts_at BETWEEN ? AND ?", "cancelled_by_client", "cancelled_by_pro", start_time, end_time] )
  end
    
  def own_bookings(start_timestamp=nil, end_timestamp=nil)
    start_time = if start_timestamp.blank?
      Time.zone.now.beginning_of_week
    else
      if start_timestamp.is_a?(Float)
        Time.at(start_timestamp)
      else
        start_timestamp.utc
      end
    end
    end_time = if end_timestamp.blank?
      Time.zone.now.end_of_week
    else
      if end_timestamp.is_a?(Float)
        Time.at(end_timestamp)
      else
        end_timestamp.utc
      end
    end
    raw_own_bookings = raw_own_bookings(start_time, end_time)
    prep_times = []
    raw_own_bookings.each do |b|
      b.current_pro = self
      my_prep = b.prep
      prep_times << my_prep unless my_prep.nil?
    end
    raw_own_bookings + bookings_for_non_working_days(start_time, end_time) + bookings_for_working_hours(start_time, end_time) + prep_times
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
    raw_bookings = Booking.find_all_by_practitioner_id(self.id, :conditions => ["state <> ? AND state <> ? AND starts_at BETWEEN ? AND ?", "cancelled_by_client", "cancelled_by_pro", start_time.utc, end_time.utc] )
    prep_times = []
    raw_bookings.each do |b|
      b.current_client = current_client
      my_prep = b.prep
      prep_times << my_prep unless my_prep.nil?
    end
    raw_bookings + prep_times
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
    res = []
    non_working_days_in_timeframe(start_time, end_time).each do |date|
      day, month, year = date.strftime("%d %m %Y").split(" ")
      res << NonWorkingBooking.new("#{self.id}-#{day}-#{month}-#{year}", I18n.t(:non_working), Time.parse("#{year}/#{month}/#{day} #{biz_hours_start}"), Time.parse("#{year}/#{month}/#{day} #{biz_hours_end}"), true)      
    end
    res
  end
  
  def non_working_days_in_timeframe(start_time, end_time)
    current = start_time
    res = []
    extras = extra_working_days_in_timeframe(start_time, end_time)
    extra_nons = extra_non_working_days_in_timeframe(start_time, end_time)
    while current < end_time
      week_day = current.strftime("%w")
      #for us Sunday is 7, for Ruby it's 0
      week_day = "7" if week_day == "0"
      if (!working_days.blank? && !extras.include?(current.to_date) && !working_days.include?(week_day)) || extras.include?(current.to_date)
        res << current.to_date
      end
      current += 1.day
    end
    res
  end
  
  def working_days_in_timeframe(start_time, end_time)
    current = start_time
    res = []
    extras = extra_working_days_in_timeframe(start_time, end_time)
    extra_nons = extra_non_working_days_in_timeframe(start_time, end_time)
    while current < end_time
      week_day = current.strftime("%w")
      #for us Sunday is 7, for Ruby it's 0
      week_day = "7" if week_day == "0"
      if (!working_days.blank? && !extra_nons.include?(current.to_date) && working_days.include?(week_day)) || extras.include?(current.to_date)
        res << current.to_date
      end
      current += 1.day
    end
    res
  end
  
  def extra_working_days_in_timeframe(start_time, end_time)
    self.extra_working_days.find(:all, :conditions => ["day_date BETWEEN ? AND ?", start_time.to_date, end_time.to_date] )
  end
  
  def extra_non_working_days_in_timeframe(start_time, end_time)
    self.extra_non_working_days.find(:all, :conditions => ["day_date BETWEEN ? AND ?", start_time.to_date, end_time.to_date] )
  end
  
  def extra_non_working_day(day_date)
    self.extra_non_working_days_in_timeframe(day_date-1.day, day_date+1.day).try(:first)
  end
    
  def extra_working_day(day_date)
    self.extra_working_days_in_timeframe(day_date-1.day, day_date+1.day).try(:first)
  end
  
  def has_bookings_on?(day_date)
    !self.client_bookings(nil, day_date.beginning_of_day, day_date.end_of_day).blank?
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
            res << NonWorkingBooking.new("#{self.id}-#{day}-#{month}-#{year}-#{slot_start_time}", I18n.t(:lunch), Time.parse("#{year}/#{month}/#{day} #{TimeUtils.fix_minutes(slot_start_time)}"), Time.parse("#{year}/#{month}/#{day} #{TimeUtils.fix_minutes(slot_end_time)}"), true)
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
