require File.dirname(__FILE__) + '/../../lib/helpers'

class UserMailer < ActionMailer::Base

  def setup_email(client)
    default_url_options[:host] = APP_CONFIG[:site_domain]
    default_url_options[:protocol] = APP_CONFIG[:site_protocol]
    @recipients = "#{client.email}"
    @from = APP_CONFIG[:contact_email]
    @subject = "[#{APP_CONFIG[:site_name]}] "
    @sent_on = Time.now
    @content_type = 'text/html'
    @body[:client] = client
    #record that an email was sent (except for mass emails)
    if client.is_a?(Client) && caller_method_name != "mass_email"
      ClientEmail.create(:client => client, :email_type => caller_method_name, :sent_at => Time.now)
    end
  end
  
  def setup_sender(pro=nil)
    if pro.nil?
      @body[:sender] = ProStub.new("The #{APP_CONFIG[:site_name]} team")
    else
      @body[:sender] = pro
    end
  end
  
  def caller_method_name
      parse_caller(caller(2).first).last
  end

  def initial_client_email(pro, client, email_text, email_signoff)
    setup_email(client)
    @from = pro.email
    @subject = "Book appointments with me online"
    if !client.first_name.blank?
      text = "Dear #{client.first_name},<br/>"
    else
      text = "Hello,<br/>"
    end
    @body[:text] = text + email_text.gsub(/\n/, "<br/>")
    @body[:link] = practitioner_url(pro.permalink, :email => client.email )
    @body[:signoff] = email_signoff.gsub(/\n/, "<br/>")
    @body[:pro_first_name] = pro.first_name
  end

  def booking_reminder(booking)
    setup_email(booking.client)
    setup_sender(booking.practitioner)
    @subject << "You have an appointment tomorrow with #{booking.practitioner.name}"
    @body[:booking] = booking
  end

  def booking_pro_reminder(pro)
    @bookings = pro.bookings.need_pro_reminder
    setup_email(pro)
    setup_sender
    @subject << "You have #{help.pluralize(@bookings.size, 'appointment')} tomorrow"
    @body[:bookings] = @bookings
    @body[:pro] = pro
  end

  def reset_phone(client)
    setup_email(client)
    setup_sender
    @subject << "You have requested to reset your phone number"
    @body[:reset_link] = reset_phone_url(:reset_code => client.reset_code)
  end

  def parse_caller(at)
      if /^(.+?):(\d+)(?::in `(.*)')?/ =~ at
          file = Regexp.last_match[1]
  		line = Regexp.last_match[2].to_i
  		method = Regexp.last_match[3]
  		[file, line, method]
  	end
  end

end
