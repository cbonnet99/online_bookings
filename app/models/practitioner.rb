class Practitioner < ActiveRecord::Base
  include Permalinkable
  
  has_many :bookings

  # new columns need to be added here to be writable through mass assignment
  attr_accessible :username, :email, :password, :password_confirmation
  
  attr_accessor :password
  before_save :prepare_password
  
  validates_presence_of :working_hours
  validates_format_of :working_hours, :with => /\-/, :message => "should contain at least one dash to denote start and end times"
  validates_format_of :username, :with => /^[-\w\._@]+$/i, :allow_blank => true, :message => "should only contain letters, numbers, or .-_@"
  validates_format_of :email, :with => /^[-a-z0-9_+\.]+\@([-a-z0-9]+\.)+[a-z0-9]{2,4}$/i
  validates_presence_of :password, :on => :create
  validates_confirmation_of :password
  validates_length_of :password, :minimum => 4, :allow_blank => true
  validates_uniqueness_of :email

  TITLE_FOR_NON_WORKING = "Booked"

  def biz_hours_start
    TimeUtils.round_previous_hour(working_hours.split("-").first)
  end
  
  def biz_hours_end
    TimeUtils.round_next_hour(working_hours.split("-").last)
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
    raw_bookings = Booking.find_all_by_practitioner_id(self.id, :conditions => ["starts_at BETWEEN ? AND ?", start_time, end_time] )
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
    ("1".."7").to_a.each do |current_day|
      if !working_days.blank? && !working_days.include?(current_day)
        day, month, year = current.strftime("%d %m %Y").split(" ")
        res << NonWorkingBooking.new("#{self.id}-#{current_day}", TITLE_FOR_NON_WORKING, Time.parse("#{year}/#{month}/#{day} #{biz_hours_start}").iso8601, Time.parse("#{year}/#{month}/#{day} #{biz_hours_end}").iso8601, true)
      end
      current += 1.day
    end
    res
  end
  
  def bookings_for_working_hours(start_time, end_time)
    res = []
    current = start_time
    ("1".."7").to_a.each do |current_day|
      if !working_days.blank? && working_days.include?(current_day)
        day, month, year = current.strftime("%d %m %Y").split(" ")
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
            res << NonWorkingBooking.new("#{self.id}-#{current_day}", TITLE_FOR_NON_WORKING, Time.parse("#{year}/#{month}/#{day} #{TimeUtils.fix_minutes(slot_start_time)}").iso8601, Time.parse("#{year}/#{month}/#{day} #{TimeUtils.fix_minutes(slot_end_time)}").iso8601, true)
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
