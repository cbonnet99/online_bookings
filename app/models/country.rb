class Country < ActiveRecord::Base
  
  has_many :clients
  has_many :practitioners

  def default_timezone
    self.timezones.split(",").first
  end

  def recreate_test_user(number_clients=30, number_bookings=150)
    self.practitioners.test_user.each{|p| p.delete}
    pro = Practitioner.new(:first_name => self.demo_first_name, :last_name => self.demo_last_name, :timezone => self.default_timezone,
        :country => self,  
        :email => self.demo_email, :password => self.demo_password, :password_confirmation => self.demo_password,
        :working_hours => "8-18", :working_days => "1,2,3,4,5", :no_cancellation_period_in_hours => Practitioner::DEFAULT_CANCELLATION_PERIOD,
        :phone => self.demo_phone)
    pro.save!
    pro.create_sample_data!(number_clients, number_bookings)
    
  end
  
  def self.default_country
    Country.all.select{|c| c.is_default?}.first
  end
  
  def self.available_countries
    Country.find(:all, :order => "is_default desc, name")
  end
  
  def self.available_country_codes
    Country.available_countries.map(&:country_code)
  end
  
  def mobile_phone_prefixes
    mobile_phone_prefixes_list.split(",").map(&:strip)
  end

  def landline_phone_prefixes
    landline_phone_prefixes_list.split(",").map(&:strip)
  end
  
  def lowercase_locale
    locale.downcase
  end

end
