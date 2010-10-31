class Reminder < ActiveRecord::Base
  belongs_to :booking
  
  
  named_scope :unsent, :conditions =>  "sent_at IS NULL"
  named_scope :need_sending, lambda { {:conditions =>  ["sending_at <= ? and sent_at IS NULL", Time.now.utc]} }
  
  def send_by_email!
    self.booking.send_reminder_email!
    self.update_attribute(:sent_at, Time.now)
  end
end
