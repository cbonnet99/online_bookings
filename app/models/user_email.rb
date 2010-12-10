class UserEmail < ActiveRecord::Base
  
  belongs_to :practitioner
  belongs_to :client
  belongs_to :booking
  
  PRO_INVITE = "pro_invite"
  CLIENT_INVITE = "client_invite"
  
  BATCH = 15
  
  named_scope :unsent, {:conditions => ["sent_at IS NULL"]}
  
  def self.send_unsent_emails
    sent = 0
    UserEmail.unsent.each do |email|
      if sent >= BATCH
        break
      end
      if email.practitioner.test_user?
        if email.to == email.practitioner.email
          email.send!
          sent += 1
        else
          #pretend we sent it: this is only a test user
          email.mark_as_sent!
        end
      else
        email.send!
        sent += 1
      end
    end
  end

  def mark_as_sent!
    self.update_attribute(:sent_at, Time.zone.now)
  end

  def send!
    if self.created_at.advance(:minutes  => self.delay_mins).utc < Time.now.utc
      email_call = "deliver_#{self.email_type}".to_sym
      begin
        UserMailer.send(email_call, self.to, self.from, self.subject, self.booking)
        puts "Sent email #{self.email_type} to #{self.to}"
        self.mark_as_sent!
      rescue NoMethodError
        puts "ERROR: Cannot send user email ID #{self.id}, email type #{self.email_type} does not correspond to any method in UserMailer"
        logger.error("Cannot send user email ID #{self.id}, email type #{self.email_type} does not correspond to any method in UserMailer")
      end
    end    
  end
      
end
