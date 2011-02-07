class Reminder < ActiveRecord::Base
  cattr_reader :per_page
  @@per_page = 10
  
  belongs_to :booking

  validates_presence_of :booking
  
  named_scope :unsent, :conditions =>  "sent_at IS NULL"
  named_scope :need_sending, lambda { {:conditions =>  ["sending_at <= ? and sent_at IS NULL", Time.now.utc]} }
  
  TYPES = {:email => "email", :sms => "sms"}
  
  def to_s
    if !sent_at.nil?
      "For booking #{booking} was sent on #{sent_at} by #{reminder_type}"
    else
      "For booking #{booking} will be sent on #{sending_at}"
    end
  end
  
  def mark_as!(type)
    self.update_attribute(:reminder_type, TYPES[type])
  end

  def mark_as_sent!
    self.update_attribute(:sent_at, Time.now.in_time_zone(self.booking.practitioner.timezone))    
  end
  
  def send_by_email!
    if !self.booking.practitioner.test_user? || (self.booking.practitioner.test_user? && self.booking.client.email == self.booking.practitioner.email)
      sent_email = UserMailer.deliver_booking_reminder(self.booking)
      Rails.logger.info("Sent booking reminder for #{self.booking}")
      self.update_attribute(:reminder_text, sent_email.body)
      self.mark_as!(:email)
    end
    #even if no email was sent, we mark it as sent
    self.mark_as!(:email)
    self.mark_as_sent!
  end
  
  def send!
    send_by_sms!
  end

  def send_by_sms!
    #send a copy by email as well
    send_by_email!
    if !self.booking.practitioner.test_user? || (self.booking.practitioner.test_user? && Administration::ADMIN_PHONES.include?(self.booking.client.phone))
      if self.booking.practitioner.has_sms_credit?
        if RAILS_ENV == "production"
          api = Clickatell::API.authenticate('3220575', 'cbonnet99', 'mavslr55')
          api.send_message(self.booking.client.phone, self.booking.sms_reminder_text.to_gsm0338)
          self.update_attribute(:reminder_text, self.booking.sms_reminder_text)
        end
        self.mark_as!(:sms)
        self.booking.practitioner.update_attribute(:sms_credit, self.booking.practitioner.sms_credit - 1)
      end
    end
    #even if no email was sent, we mark it as sent
    self.mark_as_sent!
  end

end
