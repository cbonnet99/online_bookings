class TaskUtils
  PRO_ARRAYS = [["Cyrille", "Bonnet", "cb@gmail.com", "04 34 55 45 23"], ["Kartini", "Thomas", "kt@gmail.com", "04 34 55 45 11"]]

  def self.end_bookings_grace_period
    Booking.ending_grace_period.each do |b|
      b.end_grace_period!
    end
  end
  
  def self.delete_sample_data
    unless Rails.env.production?
      Practitioner.test_user.each do |p|
        p.delete_sample_data!
      end
    end
  end
  
  def self.create_sample_data(number_clients=30, number_bookings=150)
    
    #French pro
    Time.zone = "Paris"
    pro_array = PRO_ARRAYS.first
    france = Country.find_by_country_code("FR")
    pro = Practitioner.new(:first_name => pro_array[0], :last_name => pro_array[1], :timezone => "Paris",
        :country => france,  
        :email => pro_array[2], :password => pro_array[0][0,4], :password_confirmation => pro_array[0][0,4],
        :working_hours => "8-18", :working_days => "1,2,3,4,5", :no_cancellation_period_in_hours => Practitioner::DEFAULT_CANCELLATION_PERIOD,
        :phone => pro_array[3])
    pro.save!
    pro.create_sample_data!(number_clients, number_bookings)
    
    #NZ pro
    Time.zone = "Wellington"
    pro_array = PRO_ARRAYS.second
    pro = Practitioner.new(:first_name => pro_array[0], :last_name => pro_array[1], :timezone => "Wellington",
        :country => Country.find_by_country_code("NZ"),  
        :email => pro_array[2], :password => pro_array[0][0,4], :password_confirmation => pro_array[0][0,4],
        :working_hours => "8-18", :working_days => "1,2,3,4,5", :no_cancellation_period_in_hours => Practitioner::DEFAULT_CANCELLATION_PERIOD,
        :phone => pro_array[3])
    pro.save!
    pro.create_sample_data!(number_clients, number_bookings)
    
    
  end
    
  def self.send_reminders
    Reminder.need_sending.each do |r|
      puts "Sending reminder to: #{r.booking.client.name} for appointment at #{r.booking.starts_at}"
      r.send_by_email!
    end
  end
  
  def self.send_pro_reminders
    Practitioner.need_reminders.each do |pro|
      puts "Sending PRO reminder to: #{pro.name}"
      pro.send_reminder!
    end    
  end
  
end