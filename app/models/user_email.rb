class UserEmail < ActiveRecord::Base
  
  belongs_to :practitioner
  belongs_to :client
  belongs_to :booking
  
  PRO_INVITE = "pro_invite"
  CLIENT_INVITE = "client_invite"
  CANCELLATION_NOTICE = "cancellation_notice"
  
  BATCH = 15
  
  named_scope :unsent, {:conditions => ["sent_at IS NULL"]}
  
  def self.send_unsent_emails
    sent = 0
    UserEmail.unsent.each do |email|
      if sent >= BATCH
        break
      end
      if email.created_at.advance(:minutes  => email.delay_mins).utc < Time.now.utc
        email_call = "deliver_#{email.email_type}".to_sym
        begin
          UserMailer.send(email_call, email.to, email.from, email.subject, email.booking)
          puts "Sent email #{email.email_type} to #{email.to}"
          email.update_attribute(:sent_at, Time.zone.now)
          sent += 1
        rescue NoMethodError
          puts "ERROR: Cannot send user email ID #{email.id}, email type #{email.email_type} does not correspond to any method in UserMailer"
          logger.error("Cannot send user email ID #{email.id}, email type #{email.email_type} does not correspond to any method in UserMailer")
        end
      end
    end
  end
  
end
