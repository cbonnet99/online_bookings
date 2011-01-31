require File.dirname(__FILE__) + '/../../lib/helpers'

class UserMailer < ActionMailer::Base

  def setup_email(to, from=nil)
    default_url_options[:host] = APP_CONFIG[:site_domain]
    default_url_options[:protocol] = APP_CONFIG[:site_protocol]
    @recipients = to
    from =  APP_CONFIG[:contact_email] if from.nil?
    @from = from
    @subject = ""
    @sent_on = Time.zone.now
    @content_type = 'text/html'
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
    setup_email(client.email)
    @from = pro.email
    @subject = I18n.t(:initial_client_email_subject)
    @body[:link] = practitioner_url(pro.permalink, :email => client.email )
    @body[:signoff] = email_signoff.gsub(/\n/, "<br/>")
    @body[:pro] = pro
    @body[:client] = client
  end

  def cancellation_notice(booking, cancellation_text)
    setup_email(booking.client.email)
    setup_sender(booking.practitioner)
    @subject << I18n.t(:your_booking_was_cancelled, :pro_name => booking.practitioner.name)
    @body[:cancellation_text] = cancellation_text
  end

  def booking_reminder(booking)
    setup_email(booking.client.email)
    setup_sender(booking.practitioner)
    @subject << I18n.t(:you_have_booking, :pro_name => booking.practitioner.name, :booking_time => booking.start_date_and_time_str)
    @body[:booking] = booking
    @body[:client] = booking.client
  end

  def booking_pro_reminder(pro)
    @bookings = pro.bookings.need_pro_reminder
    setup_email(pro)
    setup_sender
    @subject << I18n.t(:booking_pro_reminder_subject, :number_bookings => help.pluralize(@bookings.size, I18n.t(:booking_pro_reminder_appointment)) )
    @body[:bookings] = @bookings
    @body[:pro] = pro
  end

  def reset_phone(client)
    setup_email(client.email)
    setup_sender
    @subject << I18n.t(:reset_phone_subject)
    @body[:reset_link] = reset_phone_url(:reset_code => client.reset_code, :email  => client.email)
    @body[:client] = client
  end
  
  def client_invite(to, from, subject, booking)
    setup_email(to, from)
    @content_type = "multipart/mixed"
    @subject << subject
    if booking.practitioner.locale == "EN"
      filename = "client_invite.text.plain.erb"
    else
      filename = "client_invite.#{booking.practitioner.locale.downcase}.text.plain.erb"
    end
    part :content_type => 'multipart/alternative' do |copy|
          copy.part :content_type => 'text/plain' do |plain|
            plain.body = render( :file => filename, 
              :layout => false, :body => {:booking => booking, :booking_link => practitioner_url(booking.practitioner.permalink, :email => booking.client.email )}  )
          end
          # copy.part :content_type => 'text/html' do |html|
          #   html.body = render( :file => "client_invite.html.erb", 
          #     :layout => false, :body => {:booking => booking, :booking_link => practitioner_url(booking.practitioner.permalink, :email => booking.client.email )}  )
          # end
    end
    @body[:practitioner] = booking.practitioner
    calendar = Icalendar::Calendar.new
    calendar.add_event(booking.to_ics)
    calendar.publish
    attachment :content_type => "text/calendar", :body => calendar.to_ical, :filename => "booking.ics" 
  end

  def pro_invite(to, from, subject, booking)
    setup_email(to, from)
    @subject << subject
    if booking.practitioner.locale == "EN"
      filename = "pro_invite.text.plain.erb"
    else
      filename = "pro_invite.#{booking.practitioner.locale.downcase}.text.plain.erb"
    end
    part :content_type => 'multipart/alternative' do |copy|
      copy.part :content_type => 'text/plain' do |plain|
        plain.body = render( :file => filename, 
          :layout => false, :body => {:booking => booking, :booking_link => practitioner_url(booking.practitioner.permalink, :email => booking.client.email )}  )
      end
      # copy.part :content_type => 'text/html' do |html|
      #   html.body = render( :file => "pro_invite.html.erb", 
      #     :layout => false, :body => {:booking => booking, :booking_link => practitioner_url(booking.practitioner.permalink, :email => booking.client.email )}  )
      # end
    end
    calendar = Icalendar::Calendar.new
    calendar.add_event(booking.to_ics)
    calendar.publish
    attachment :content_type => "text/calendar", :body => calendar.to_ical, :filename => "booking.ics" 
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
