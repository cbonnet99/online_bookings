class UserMailer < ActionMailer::Base

  def setup_email(client)
    default_url_options[:host] = APP_CONFIG[:site_host]
    default_url_options[:protocol] = APP_CONFIG[:logged_site_protocol]
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
  
  def caller_method_name
      parse_caller(caller(2).first).last
  end

  def reset_phone(client)
    setup_email(client)
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
