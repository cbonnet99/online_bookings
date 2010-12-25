class Reminder < ActiveRecord::Base
  belongs_to :booking
  
  validates_presence_of :booking
  
  named_scope :unsent, :conditions =>  "sent_at IS NULL"
  named_scope :need_sending, lambda { {:conditions =>  ["sending_at <= ? and sent_at IS NULL", Time.now.utc]} }
  
  TYPES = {:email => "email", :sms => "sms"}
  
  def mark_as!(type)
    self.update_attribute(:reminder_type, TYPES[type])
  end

  def mark_as_sent!
    self.update_attribute(:sent_at, Time.now.in_time_zone(self.booking.practitioner.timezone))    
  end
  
  def send_by_email!
    self.booking.send_reminder_email!
  end
end
